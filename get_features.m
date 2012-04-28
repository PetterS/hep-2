function [F STR] = get_features(I,M,pos)

sigma= 1;
hfilter = fspecial('gaussian', [round(5*sigma) round(5*sigma)], sigma);

sigma= 2.5;
hfilter2 = fspecial('gaussian', [round(5*sigma) round(5*sigma)], sigma);

Iblur1 = imfilter(I,hfilter,'symmetric');
Iblur2 = imfilter(I,hfilter2,'symmetric');


[F1 STR1] = get_features_single(I, M, pos);
[F2 STR2] = get_features_single(Iblur1, M, pos);
[F3 STR3] = get_features_single(Iblur2, M, pos);

F = [F1,F2-F1,F3-F2];

if nargout > 1
	STR = cell(size(STR1,1)+size(STR2,1) +size(STR3,1),1);
	for im_num = 1:size(STR1,1)
		STR{im_num} = STR1{im_num};
		STR{im_num + size(STR1,1)} = [STR2{im_num} ' blur 1'];
		STR{im_num + size(STR1,1)+size(STR2,1)} = [STR3{im_num} 'blur 2'];
	end
end


function [F STR] = get_features_single(I,M,pos)
Ifull = I;
I(~M) = 0;

% Filtering out extreme outliers
intensities = double(I(logical(M)));
[n,x] = hist(intensities(:));


% Very rare occurances removed
n(n < 0.005*sum(n)) = 0;
quant_thresh = quantile(intensities(:),0.925);


thresh_level = strfind(n,[0 0]);
if ~isempty(thresh_level)
	thresh_level = thresh_level(1);
	
	if thresh_level > 1
		hist_thresh = x(thresh_level-1);
	else
		hist_thresh = x(thresh_level);
	end
	
	% If both the histogram is empty and we are above quantile
	% we remove
	if ((thresh_level < 10) && (hist_thresh > quant_thresh))
		I(I > hist_thresh)  = hist_thresh;
	end
end

% Preallocate to speed up
num_features = 1;
F = zeros(1,num_features);
STR = cell(1,num_features);
maxI = double(max(I(:)));
minI = double(min(I(:)));

ind = 1;

F(ind) = pos;  STR{ind} = 'Pos'; ind = ind+1;

% Threshold the image at many different thresholds and
% compute lots of statistics
% Possible thresholds
Theta = linspace(minI,maxI, 20);
i=0;
for theta = Theta
	i=i+1;
	
	BW = I > theta;
	CC = bwconncomp(BW);
	
	% Number of objects
	F(ind) = CC.NumObjects;  STR{ind} = ['Number of objects ' num2str(i)]; ind = ind+1;
	
	% Some regionprops
	L = zeros(size(BW));
	L(BW) = 1;
	RP = regionprops(L,{'Area', 'ConvexArea', 'Eccentricity', 'EulerNumber', ...
		'Perimeter'});
	F(ind) = fixempty(RP.Area);         STR{ind} = ['RP.Area ' num2str(i)]; ind = ind+1;
	F(ind) = fixempty(RP.ConvexArea);   STR{ind} = ['RP.ConvexArea ' num2str(i)]; ind = ind+1;
	F(ind) = fixempty(RP.Eccentricity); STR{ind} = ['RP.Eccentricity ' num2str(i)]; ind = ind+1;
	F(ind) = fixempty(RP.EulerNumber);  STR{ind} = ['RP.EulerNumber ' num2str(i)]; ind = ind+1;
	F(ind) = fixempty(RP.Perimeter);  STR{ind} = ['RP.Perimeter ' num2str(i)]; ind = ind+1;
	
	BWinterior = imerode(BW,ones(5));
	It = I;
	It(~BW) = 0;
	
	F(ind) = fixfrac(sum(It(:)),sum(BW(:)));
	STR{ind} = ['Mean intensity' num2str(i)]; ind = ind+1;
	
	F(ind) = fixfrac(entropy(It),sum(BW(:)));
	STR{ind} = 'Entropy / size';  ind = ind+1;
	
	stdfiltI = stdfilt(Ifull);
	entropyI = entropyfilt(Ifull);
	rangeI = rangefilt(Ifull);
	
	
	F(ind) = fixfrac(sum(stdfiltI(BW)),sum(BW(:)));
	STR{ind}  = 'Stdfilt / size'; ind = ind+1;
	F(ind) = fixfrac(sum(entropyI(BW)),sum(BW(:)));
	STR{ind}  = 'Entropy filt / size'; ind = ind+1;
	F(ind) = fixfrac(sum(rangeI(BW)),sum(BW(:)));
	STR{ind}  = 'Range filt / size'; ind = ind+1;
	
	F(ind) = fixfrac(sum(stdfiltI(BWinterior)) , sum(BWinterior(:)) );
	STR{ind}  = 'Interior Stdfilt / size'; ind = ind+1;
	F(ind) = fixfrac(sum(entropyI(BWinterior)) , sum(BWinterior(:)) );
	STR{ind}  = 'Interior Entropy filt / size'; ind = ind+1;
	F(ind) = fixfrac(sum(rangeI(BWinterior)) , sum(BWinterior(:)) );
	STR{ind}  = 'Interior Range filt / size'; ind = ind+1;
	
end


% Gradient image
sigma =  linspace(0.6,10.5,10);

for curr = 1:length(sigma);
	h = fspecial('gaussian', [round(3*sigma(curr)) round(3*sigma(curr))], sigma(curr));
	hx = diff(h,1,1);
	hy = diff(h,1,2);
	gradx = double( imfilter(I,hx,'symmetric') );
	grady = double( imfilter(I,hy,'symmetric') );
	G =sqrt(gradx(:).^2 +grady(:).^2);
	
	F(ind) = mean(G);        STR{ind} = ['Mean gradient sigma: ' num2str(sigma(curr))]'; ind = ind+1;
	F(ind) = median(G);      STR{ind} = ['Median gradient sigma: ' num2str(sigma(curr))]'; ind = ind+1;
	F(ind) = std(G);         STR{ind} = ['Std gradient sigma: ' num2str(sigma(curr))]'; ind = ind+1;
end


offset = [-1 1];

for level = 2:3:14
	[glcm,~] = graycomatrix(I,'NumLevels',level,'G',[],'offset', offset);
	stats = graycoprops(glcm);
	
	
	for off = 1:size(offset, 1);
		
		F(ind) = fixnan(stats.Contrast(off));
		STR{ind} = ['coContrast level/offset' num2str(level) '/' num2str(off)];
		ind = ind+1;
		
		F(ind) = fixnan(stats.Correlation(off));
		STR{ind} = ['coCorrelation level:' num2str(level)];
		ind = ind+1;
		
		F(ind) = fixnan(stats.Energy(off));
		STR{ind} = ['coEnergy level:' num2str(level) '/' num2str(off)];
		ind = ind+1;
		
		F(ind) = fixnan(stats.Homogeneity(off));
		STR{ind} = ['Homogeneity level:' num2str(level) '/' num2str(off)];
		ind = ind+1;
	end
	
end

% Aspect ratio
F(ind) = size(I,1)/size(I,2);         STR{ind} = 'Aspect ratio'; ind = ind+1; %#ok<NASGU>

function v = fixfrac(numerator,denominator)

if ~exist('numerator','var') || isempty(numerator)
	v = 0;
	
elseif  ~exist('denominator','var') || isempty(denominator)
	v= 0;
else
	
	numerator = sum(numerator(:));
	denominator = sum(denominator(:));
	
	if (denominator == 0);
		v = 1;
	else
		v = numerator/denominator;
	end
end

function v= fixnan(val)
if isnan(val)
	v = 0;
else
	v = val;
end

function v = fixempty(val)
if ~exist('val','var') || isempty(val)
	v = 0;
else
	v = val;
end
