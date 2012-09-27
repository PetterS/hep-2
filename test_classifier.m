clear all
clc

classifier_types = {'random_forest', 'svm', 'nn', '3nn', '5nn'};

n_train = 100;
n_features = 5;
n_classes = 4;
F_train = rand(100, 5);
C_train = ceil(n_classes * rand(n_train, 1));

n_test = 50;
F_test = rand(n_test, n_features);

for t = 1:length(classifier_types)
	type = classifier_types{t};
	fprintf('Testing %s... ', type);

	classifier = Classifier(type, F_train, C_train, '');
	C = classifier.classify(F_test);
	
	assert( all(size(C) == [n_test 1]) );
	
	fprintf('done.\n');
end
