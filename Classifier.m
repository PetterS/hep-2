%
% Common interface to several classifiers
%
% Methods:
%
%   Classifier(type, F,C)
%       type : {'adaboost', 'random_forest'}
%       F    : n-by-m matrix (n m-dimensional feature vectors)
%       C    : n-vector with class labels
%
%   C = self.classify(F)
%       F : n-by-m feature vector
%       C : n-vector with class labels
%
% Petter Strandmark, Johannes Ulén 2012
% petter@maths.lth.se
classdef Classifier
	%Classifier classifies data
	
	properties
		model
		F
		C
		k
		w
		normtype
		type
		nclasses
		options
		tree_correct
		tree_incorrect
	end
	
	methods
		function self = Classifier(type,F,C,options)
			self.options = options;
			self.type = type;
			self.k = 1;
			self.normtype = 1;
			self.nclasses = max(C);
			
			assert(size(F, 1) == size(C, 1));
			assert(size(C, 2) == 1);
			
			if strcmp(self.type, '3nn')
				self.k = 3;
				self.type = 'nn';
			elseif strcmp(self.type, '5nn')
				self.k = 5;
				self.type = 'nn';
			end
			
			switch self.type
				case 'adaboost'
					training_it = 25*size(F,2);
					for class = 1:self.nclasses
						fprintf('Training class %d/%d... ',class,self.nclasses);
						Y = zeros(size(C));
						Y(C==class) =  1;
						Y(C~=class) = -1;
						[~, self.model{class}]=adaboost('train',F,Y,training_it);
						fprintf('done.\n');
					end
				case 'adaboost_matlab'
					Y = num2cell(num2str(C'));
					self.model = fitensemble(F,Y,'AdaBoostM2',100,'tree');
				case 'random_forest'
					% Add the random forest code to the path if needed
					if  ~(exist('classRF_train'))
						dir = fileparts(mfilename('fullpath'));
						addpath([dir filesep 'randomforest-matlab' filesep 'RF_Class_C']);
					end
					
					if isa(options,'struct')
						local_options = options;
					end
					self.options = options;
					
					if ~isfield(self.options,'use_weighted_trees')
						self.options.use_weighted_trees = false;
					end
					
					local_options.importance = 1;
					n_trees = 500;
					n_tries = floor(sqrt(size(F,2)+1));
					
					self.model = classRF_train(F,C, n_trees, n_tries, local_options);
					
					
					if self.options.use_weighted_trees
						extra_options.predict_all = 1;
						[~, ~, W] = classRF_predict(F, self.model, extra_options);
						self.tree_correct   = zeros(n_trees,1);
						self.tree_incorrect = zeros(n_trees,1);
						for id = 1:size(W,1)
							for t = 1:size(W,2)
								if W(id,t) == C(id)
									self.tree_correct(t)   = self.tree_correct(t) + 1;
								else
									self.tree_incorrect(t) = self.tree_incorrect(t) + 1;
								end
							end
						end
					end
					
				case 'treebagger'
					n_trees = 500;
					self.model = TreeBagger(n_trees,F,C);
					
				case 'svm'
					if ~(exist('svmpredict'));
						dir = fileparts(mfilename('fullpath'));
						addpath([dir filesep  'libsvm' filesep 'matlab']);
					end
					
					if ~(exist('libsvmwrite'))
						error('Please compile LIBSVM');
					end
					
					self.model = svmtrain(C, F, options);
					
				case 'nn'
					% Compute the standard deviation of each feature
					% component.
					self.w = std(F) + eps;
					% Save the weighted features.
					self.F = F;
					for i = 1:size(self.F, 1)
						self.F(i, :) = self.F(i, :) ./ self.w;
					end
					% Save the correct classes.
					self.C = C;
					
				otherwise
					error('Unknown classifier type');
			end
		end
		
		function [C P] = classify(self,F)
			P = zeros(self.nclasses,1);
			switch self.type
				case 'adaboost'
					P = zeros(size(F,1),self.nclasses);
					for m = 1:size(F,1)
						for class = 1:self.nclasses
							[~ , ~, w(class)] = adaboost('apply', F(m,:), self.model{class});
						end
						
						C(m) = find(w==max(w),1);
						P(m,C)=1;
					end
				case 'adaboost_matlab'
					result = self.model.predict(F);
					C = zeros(length(result), 1);
					for i = 1:length(result)
						C(i) = str2num(result{i});
						P(i, C(i))=1;
					end
				case 'random_forest'
					
					if self.options.use_weighted_trees
						extra_options.predict_all = 1;
						[C P1 W] = classRF_predict(F, self.model, extra_options);
						P1 = P1./repmat(sum(P1,2), [1 size(P1,2)]);
						P = zeros(size(F,1), self.nclasses);
						
						correctw = self.tree_correct' - min(self.tree_correct(:)) + 1;
						for class = 1:self.nclasses
							P(:,class) = sum( double(W==class).* repmat(correctw, [size(F,1) 1]), 2 );
						end
						P = P ./ sum(correctw);
						
						for i=1:size(F,1)
							C(i) = find(P(i,:)==max(P(i,:)));
						end
						
					else
						[C P] = classRF_predict(F, self.model);
						P = P./repmat(sum(P,2), [1 size(P,2)]);
					end
					
				case 'treebagger'
					Res = self.model.predict(F);
					for i=1:length(Res)
						C(i) = str2double(Res{i});
					end
					P(C)=1;
				case 'svm'
					C = zeros(size(F, 1), 1);
					for i = 1:size(F, 1)
						C(i) = svmpredict(0, F(i, :), self.model);
						P(i, C(i))=1;
					end
					
				case 'nn'
					% The number of instances to classify.
					n = size(self.F, 1);
					% Allocate the output vector.
					C = zeros(size(F, 1), 1);
					for i = 1:size(F, 1)
						% The feature vector to classify should be
						% weighted.
						f = F(i, :) ./ self.w;
						% Compute the distance to the vectors in the
						% training set.
						dist = zeros(n, 1);
						for k = 1:n
							dist(k) = norm(f - self.F(k, :), self.normtype);
						end
% 						dist = sum((repmat(f, [n 1]) - self.F).^2, 2);
						% Sort the distances and find the closest classes.
						[~, ind] = sort(dist);
						ind = ind(1:self.k);
						classes = self.C(ind);
						% Pick the most common class
						C(i) = mode(classes);
						P(i, C(i))=1;
					end
			end
		end
		
		
		function detailed_info(self,F,C)
			switch self.type
				case 'adaboost'
					for class = 1:self.nclasses
						fprintf('Applying class %d on data set... ',class);
						n = size(F,1);
						Y_TRUE = zeros(n,1);
						Y_TRUE(C==class) =  1;
						Y_TRUE(C~=class) = -1;
						n = length(Y_TRUE);
						Y_TEST = adaboost('apply',F,self.model{class});
						
						TP = length(find( Y_TRUE== 1 & Y_TEST== 1  )) / n;
						TN = length(find( Y_TRUE==-1 & Y_TEST==-1  )) / n;
						FP = length(find( Y_TRUE==-1 & Y_TEST== 1  )) / n;
						FN = length(find( Y_TRUE== 1 & Y_TEST==-1  )) / n;
						fprintf(' TP=%.1f%% TN=%.1f%% FP=%.1f%% FN=%.1f%% \n',100*TP,100*TN,100*FP,100*FN);
					end
				case 'random_forest'
					
					figure(1); clf;
					for class = 1:self.nclasses
						subplot(self.nclasses+2,1,class);
						bar(self.model.importance(:,class));
						yl=ylim;
						yl(1)=0;
						ylim(yl);
						xlim([0 size(self.model.importance,1)+0.5]);
						title(sprintf('Importance for class %d',class));
					end
					subplot(self.nclasses+2,1,self.nclasses+1);
					bar(self.model.importance(:,end-1))
					yl=ylim;
					yl(1)=0;
					ylim(yl);
					xlim([0 size(self.model.importance,1)+0.5]);
					title('Mean decrease in Accuracy');
					
					subplot(self.nclasses+2,1,self.nclasses+2);
					bar(self.model.importance(:,end));
					xlim([0 size(self.model.importance,1)+0.5]);
					title('Mean decrease in Gini index');
					
					figure(2); clf;
					plot(self.model.errtr(:,1),'k');
					hold on;
					yl=ylim;
					yl(1)=0;
					ylim(yl);
					xl = xlim;
					miny = min(self.model.errtr(:,1));
					plot(xl, [miny miny], ':k');
					xlabel('iteration (# trees)');
					ylabel('OOB error rate');
					
				otherwise
					fprintf('No detailed info.\n');
			end
		end
		
	end
	
end

