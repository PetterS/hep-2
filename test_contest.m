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

%% Set up data
train = 1;
fprintf('Reading training set... ');
SET{train} = get_contest_dataset('dataset/ICPR2012_Cells_Classification_Contest/training/training.csv');
fprintf('%d training images.\n', SET{train}.n);
test = 2;
fprintf('Reading test set... ');
SET{test}  = get_contest_dataset('dataset/ICPR2012_Cells_Classification_Contest/test/test.csv');
fprintf('%d test images.\n', SET{test}.n);

[TRAINIMAGE, TESTIMAGE] = get_contest_image_correspondences( ...
	'dataset/ICPR2012_Cells_Classification_Contest/cells.csv', ... 
	SET{train}, ...
	SET{test});

%% Compute features
fprintf('Computing features... ');
parfor i = 1 : 2
	[F{i}, F_STR] = get_all_features(SET{i});
end
fprintf('done.\n');

%% Train classifier
fprintf('Training... ');
classifier = Classifier(classifier_type, F{train}, SET{train}.CLASS, classifier_options);
fprintf('done.\n');

%% Evaluate

[C, prob] = classifier.classify(F{test});

matrix = zeros(6,6);
for j = 1:length(C)
	true = SET{test}.CLASS(j);
	classified = C(j);
	matrix(true,classified) = matrix(true,classified)  + 1;
end

matrix
fprintf('Total correct cell rate               : %.1f%%\n',sum(diag(matrix))/sum(matrix(:))*100);

%% Compute image classification.

matrix_large_image            = zeros(6,6);
matrix_large_image_electoral_votes = zeros(6,6);
matrix_large_image_weighted = zeros(6,6);


for im = unique(TESTIMAGE)
	ind = TESTIMAGE == im;
	image_class = mode(C(ind));
	
	assert(length(unique(SET{test}.CLASS(ind))) == 1);
	true_image_class = mode(SET{test}.CLASS(ind));

	matrix_large_image(true_image_class, image_class) = ...
		matrix_large_image(true_image_class, image_class) + 1;
	
	% Classify entire image in a smart way.
	[image_class, good_prob] = classify_image(C(ind), prob(ind, :));
	matrix_large_image_electoral_votes(true_image_class, image_class) = ...
		matrix_large_image_electoral_votes(true_image_class, image_class) + 1;
    
    [~,max_prob] = max(sum(prob(ind,:),1));
    
    matrix_large_image_weighted(true_image_class, max_prob) =  ...
    matrix_large_image_weighted(true_image_class, max_prob)  +1;                      
end

matrix_large_image %#ok<NOPTS>
fprintf(...
	'Total correct image rate              : %.1f%%\n',...
	sum(diag(matrix_large_image))/length(unique(TESTIMAGE))*100);
matrix_large_image_electoral_votes %#ok<NOPTS>
fprintf(...
	'Total correct image rate (electoral votes) : %.1f%%\n',...
	sum(diag(matrix_large_image_electoral_votes))/length(unique(TESTIMAGE))*100);

fprintf(...
	'Total correct image rate (weighted votes) : %.1f%%\n',...
	sum(diag(matrix_large_image_weighted))/length(unique(TESTIMAGE))*100);
