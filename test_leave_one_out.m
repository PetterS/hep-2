clear all
clc

% The type of classifier to use 
classifier_type = 'random_forest';
%classifier_type = 'adaboost';
%classifier_type = 'svm';

switch classifier_type
    case 'svm'
        classifier_options = '-t 1 -d 3 -gamma 100';
    otherwise  
        classifier_options = '';
end

show_errors = 1;
write_error_files = true;

% The data set to use
csvfile = 'training/training.csv';

%% Set up data

% Read data set
[path name ext] = fileparts(csvfile);
SET             = get_dataset(csvfile);
% Get all features
[F F_STR]  = get_all_features(SET);

%% Leave-one-out cross-validation
close all
h = waitbar(0,'Performing  leave-one-out cross-validation... ');
% classifier = Classifier(classifier_type, F,SET.CLASS, classifier_options);

matrix = zeros(6,6);
prob_correct   = [];
prob_incorrect = [];
ALL = 1:size(F,1);
TEST = ALL;
for id = TEST	
	
	TRAIN = setdiff(ALL,id);
	classifier = Classifier(classifier_type, F(TRAIN,:),SET.CLASS(TRAIN), classifier_options);

	[estimated prob] = classifier.classify(F(id,:));
	true      = SET.CLASS(id);
	
	matrix(true,estimated) = matrix(true,estimated)  + 1;
	
	if estimated == true
		prob_correct(end+1) = prob(estimated);
	else
		prob_incorrect(end+1) = prob(estimated);
		
		if  show_errors
            i = show_classification_error(SET,id,estimated,prob);
			if write_error_files
				imwrite(i,sprintf('test/error%d.png',length(prob_incorrect)));
			end
        end
	end
	
	waitbar(id/length(TEST), h);
end
close(h);


%% Error/reject

probabilities = linspace(0,1,100);

n=0;
for itr = probabilities
   n = n+1;
   number_false = sum(prob_incorrect > itr);
   number_true = sum(prob_correct > itr);
   
   accuracy(n) =   number_true/(number_true + number_false);
   if isnan(accuracy(n))
	   accuracy(n) = 1; % 0 correct out of 0
   end
   classified(n) = (number_true + number_false)/ numel(TEST);     
end

reject_rate = 1-classified;
error_rate = 1-accuracy;

figure()
plot((1-classified)*100,accuracy*100,'linewidth',3)
AUC = trapz((1-classified),accuracy); % Even though we don't like it
ylabel('Accuracy (%)');
xlabel('Reject rate (%)');
xlim([0 100]);
yl = ylim;
ylim(yl + [0 0.1]);

ii = find(accuracy==1,1);
rrate = 1-classified(ii);
fprintf('Reject rate needed for 100%%: %.1f%%\n',rrate*100);
fprintf('Total correct rate for cross-validation : %.1f%%\n',sum(diag(matrix))/numel(TEST)*100);


