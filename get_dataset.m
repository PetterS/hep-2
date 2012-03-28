function SET = get_dataset(csvfile)

[path name ext] = fileparts(csvfile);

file = fopen(csvfile);
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
SET.CLASS = CLASS;
SET.path = path;
SET.name = name;
SET.ext = ext;

