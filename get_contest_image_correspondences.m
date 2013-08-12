function [TRAINIMAGE, TESTIMAGE] = ...
	get_contest_image_correspondences(csvfile, TRAINSET, TESTSET)

[path name ext] = fileparts(csvfile);

file = fopen(csvfile, 'r');
if file == -1
	error('Failed to open file.');
end


[A, c] = textscan(file,'%s%s%s%s%s%s%s%s','Delimiter',';');
n = length(A{1})-1;

CONTEST_ID = zeros(1, n);
CLASS = zeros(1, n);
POS = zeros(1,n);
for i = 1 : n
	CONTEST_ID(i)  = str2double(A{1}{i+1});
	POS(i) = strcmp(A{4}{i+1}, 'positive');
	switch A{6}{i+1}
		case 'homogeneous'
			CLASS(i) = 1;
		case 'coarse_speckled'
			CLASS(i) = 2;
		case 'fine_speckled'
			CLASS(i) = 3;
		case 'nucleolar'
			CLASS(i) = 4;
		case 'centromere'
			CLASS(i) = 5;
		case 'cytoplasmatic'
			CLASS(i) = 6;
		otherwise
			error('Unknown class ');
	end

	if strcmp(A{2}{i+1}, 'training')
		assert(CLASS(i) == TRAINSET.CLASS(i));
		assert(POS(i) == TRAINSET.POS(i));
		image = str2double(A{3}{i+1});
		TRAINIMAGE(i) = image;
	elseif strcmp(A{2}{i+1}, 'test')
		assert(CLASS(i) == TESTSET.CLASS(i - TRAINSET.n));
		assert(POS(i) == TESTSET.POS(i - TRAINSET.n));
		image = str2double(A{3}{i+1});
		TESTIMAGE(i - TRAINSET.n) = image;
	else
		error('Unknown set');
	end
end
fclose(file);


