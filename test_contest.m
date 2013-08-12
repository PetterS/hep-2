clear all
clc

% Faster if you use: matlabpool open.

% Are you using the dataset released prior to ICPR workshop
ICPR_dataset = true;

% If you are using the new version uncomment below.
% ICPR_dataset = false;

% The type of classifier to use
classifier_type = 'random_forest';
% classifier_type = 'adaboost';
%classifier_type = 'svm';

switch classifier_type
	case 'svm'
		classifier_options = '-t 1 -d 3 -gamma 100';
	otherwise
		classifier_options = '';
end

show_errors = false;
write_error_files = false;

%% Set up data
train = 1;
test = 2;
		
if (ICPR_dataset)
	fprintf('Reading training set... ');
	SET{train} = get_contest_dataset('dataset/ICPR2012_Cells_Classification_Contest/training/training.csv');
	fprintf('%d training images.\n', SET{train}.n);

	fprintf('Reading test set... ');
	SET{test}  = get_contest_dataset('dataset/ICPR2012_Cells_Classification_Contest/test/test.csv');
	fprintf('%d test images.\n', SET{test}.n);
	
	[TRAINIMAGE, TESTIMAGE] = get_contest_image_correspondences( ...
		'dataset/ICPR2012_Cells_Classification_Contest/cells.csv', ...
		SET{train}, ...
		SET{test});
	
	testing_ids = unique(TESTIMAGE);
	
	%% Compute features
	fprintf('Computing features... ');
	parfor i = 1 : 2
		[F{i}, F_STR] = get_all_features(SET{i});
	end
	fprintf('done.\n');

	train_classes = SET{train}.CLASS;
	test_classes = SET{test}.CLASS;
	
% New dataset release
else	
	total_number_of_cells = 0;
	training_ids = [1,2,3,5,6,7,8,9,11,14,18,20,25,26];
	testing_ids = [4,10,12,13,15,16,17,19,21,22,23,24,27,28];
	
	n_images = numel(training_ids) + numel(testing_ids);
	
	parfor i = 1:n_images
		csv_filename  = sprintf('dataset/Main_Dataset/Images/%02d/%02d.csv', i, i);
		SET{i} = read_large_image(csv_filename); %#ok<SAGROW>
		
		fprintf('Image %d, %d cells.\n', i, SET{i}.n);
		total_number_of_cells = total_number_of_cells + SET{i}.n;
	end
	fprintf('Total number of cells is %d\n', total_number_of_cells);
	 

	% Calculate all features
	parfor i = 1:n_images
		[Fn{i}, F_STR] = get_all_features(SET{i});
	end
	
	% Reformat
	F{1} = []; 
	F{2} = [];
	train_classes = [];
	test_classes = [];
	% Compute features
	
	for i = training_ids
		F{1} = [F{1}; Fn{i}];
		train_classes =  [train_classes; SET{i}.CLASS'];
	end

	for i = testing_ids
		 F{2} = [F{2}; Fn{i}];
		 test_classes =  [test_classes; SET{i}.CLASS'];
	end
end


%% Train classifier
fprintf('Training... ');
classifier = Classifier(classifier_type, F{train}, train_classes, classifier_options);
fprintf('done.\n');

%% Evaluate
[C, prob] = classifier.classify(F{test});

matrix = zeros(6,6);
for j = 1:length(C)
	true = test_classes(j);
	classified = C(j);
	matrix(true,classified) = matrix(true,classified)  + 1;
end

matrix
fprintf('Total correct cell rate               : %.1f%%\n',sum(diag(matrix))/sum(matrix(:))*100);