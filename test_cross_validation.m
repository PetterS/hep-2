clear all
clc

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

n_images = 28;

%% Set up data

% Read data set
total_number_of_cells = 0;
for i = 1:n_images
	csv_filename  = sprintf('dataset/Main_Dataset/Images/%02d/%02d.csv', i, i);
	SET{i} = read_large_image(csv_filename); %#ok<SAGROW>
	
	fprintf('Image %d, %d cells.\n', i, SET{i}.n);
	total_number_of_cells = total_number_of_cells + SET{i}.n;
end
fprintf('Total number of cells is %d\n', total_number_of_cells);


%% Compute features
for i = 1:n_images
	[F{i}, F_STR] = get_all_features(SET{i}); %#ok<SAGROW>
end

%% Cross-validation
close all
h = waitbar(0,sprintf('Performing %d-fold cross-validation... ', n_images));

matrix = zeros(6,6);
matrix_lage_image = zeros(6,6);
prob_correct   = [];
prob_incorrect = [];
incorrect = [];
for i = 1:n_images
	F_TEST = F{i};
	C_TEST = SET{i}.CLASS(:);
	train_id = setdiff(1:length(SET), i);
	F_TRAIN = zeros(0, size(F_TEST, 2));
	C_TRAIN = [];
	for j = 1:n_images
		if j ~= i
			F_TRAIN = [F_TRAIN; F{j}];
			C_TRAIN = [C_TRAIN; SET{j}.CLASS(:)];
		end
	end
			
	classifier = Classifier(classifier_type, F_TRAIN, C_TRAIN, classifier_options);
	
	[C, prob] = classifier.classify(F_TEST);
	
	for j = 1:length(C_TEST)
		true = C_TEST(j);
		classified = C(j);
		matrix(true,classified) = matrix(true,classified)  + 1;
	end

	% Classify entire image.
	image_class = mode(C);
	true_image_class = mode(C_TEST);
	matrix_large_image(true_image_class, image_class) = ...
		matrix_large_image(true_image_class, image_class) + 1;
	
	if true_image_class == image_class
		fprintf('Image %d correctly classified.\n', i);
	else
		fprintf('Image %d incorrect.\n', i);
	end
	
	waitbar(i/n_images, h);
end
close(h);

matrix %#ok<NOPTS>
matrix_large_image %#ok<NOPTS>
fprintf('Total correct rate for cross-validation       : %.1f%%\n',sum(diag(matrix))/total_number_of_cells*100);
fprintf('Total correct image rate for cross-validation : %.1f%%\n',sum(diag(matrix_lage_image))/n_images*100);


