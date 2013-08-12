function SET = get_contest_dataset(csvfile)

[path name ext] = fileparts(csvfile);

file = fopen(csvfile, 'r');
if file == -1
	error('Failed to open file.');
end

try
	[A c] = textscan(file,'%s%s%s%s','Delimiter',';');
	n = length(A{1})-1;

	ID = zeros(1,n);
	POS = zeros(1,n);
	for i = 1:n
		ID(i)  = str2num(A{1}{i+1});
		POS(i) = strcmp(A{2}{i+1},'positive');
	end
	fclose(file);
catch err
	fclose(file);
	error(err.identifier,err.message);
end

gtfile = sprintf('%s%sgt_%s%s',path,filesep,name,ext);
file = fopen(gtfile);
if file<0
	error(['Could not find ' gtfile]);
end

try
	[A c] = textscan(file,'%s%s','Delimiter',';');
	n = length(A{1})-1;

	ID = zeros(1,n);
	CLASS = zeros(1,n);
	for i = 1:n
		ID(i)  = str2num(A{1}{i+1});
		switch A{2}{i+1}
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
		end
	end
	fclose(file);
catch err
	fclose(file);
	error(err.identifier,err.message);
end

SET.classes = 6;
SET.n = n;
SET.ID = ID;
SET.POS = POS;
SET.CLASS = CLASS';
SET.path = path;
SET.name = name;
SET.ext = ext;

% Compatibility with read_large_image
SET.filename = name;

% PCA
meanI = [ 3.4568 41.4073 0.3621];
comp  = [0.0592 0.9982 0.0006];

for id = SET.ID
	image_file = sprintf('%s%s%03d.png',SET.path,filesep,id);
	mask_file  = sprintf('%s%s%03d_mask.png',SET.path,filesep,id);
	
	image = double(imread(image_file));
	[m, n, three] = size(image);
	assert(three == 3);
	MI = repmat(reshape(meanI,[1 1 3]),[m n 1]);
	image = image - MI;
	image = 255 * rgb2gray(reshape(1/255*meanI,[1 1 3])) + ...
	        sum(image .* repmat(reshape(comp,[1 1 3]),[m n 1]), 3);
	image = uint8(image);
	
	mask = imread(mask_file);
	
	SET.I{id} = image;
	SET.M{id} = mask;
end
