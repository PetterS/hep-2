function SET = read_large_image(csv_filename)
	[base_path, base_name] = fileparts(csv_filename);
    
	image_filename = [base_path filesep base_name '.bmp'];
    
    cell_path = [base_path filesep '..' filesep '..' filesep 'Cells' filesep 'Cell_Images' filesep base_name];
    mask_path  = [base_path filesep '..' filesep '..' filesep 'Cells' filesep 'Cell_Masks' filesep base_name];

    
	fid = fopen(csv_filename);
	fgetl(fid);
	Data = textscan(fid, '%s%d%d%d%s%s%d%d%d%d', ...
	                'Delimiter', ';');
	fclose(fid);
	
	% PCA
	meanI = [ 3.4568 41.4073 0.3621];
	comp  = [0.0592 0.9982 0.0006];
	
    dc = dir(cell_path);
    dm = dir(mask_path);
        
	image = double(imread(image_filename));
	[m, n, three] = size(image);
	assert(three == 3);
	MI = repmat(reshape(meanI,[1 1 3]),[m n 1]);
	image = image - MI;
	image = 255 * rgb2gray(reshape(1/255*meanI,[1 1 3])) + ...
	        sum(image .* repmat(reshape(comp,[1 1 3]),[m n 1]), 3);
	image = uint8(image);
	
	n = length(Data{1});
	i = 0;
	for j = 1:n
		if strcmp(Data{5}{j}, 'cell')
			i = i + 1;
			
			ID(i)  = Data{2}(j);
			POS(i) = strcmp(Data{1}{j},'positive');
			switch Data{6}{j}
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
				case 'centromeric'
					CLASS(i) = 5;
				case 'cytoplasmatic'
					CLASS(i) = 6;
				otherwise
					error(['Unknown class ' Data{6}(j)]);
			end
			
			minX = Data{7}(j);
			minY = Data{8}(j);
			maxX = Data{9}(j);
			maxY = Data{10}(j);
			
            % Read mask
            mask = imread(sprintf('%s%03d.png', [mask_path filesep], ID(i)));
            [ii, jj] = find(mask);
            I{i} = image(min(ii):max(ii), min(jj):max(jj));
            M{i} = mask(min(ii):max(ii), min(jj):max(jj));
            assert( abs(min(ii) - minY) <= 2);
            assert( abs(max(ii) - maxY) <= 2);
            assert( abs(min(jj) - minX) <= 2);
            assert( abs(max(jj) - maxX) <= 2);
            
% 			I{i} = image(minY:maxY, minX:maxX);
% 			M{i} = mask(minY:maxY, minX:maxX);
		end
	end
	
	SET.classes = 6;
	SET.n = i;
	SET.ID = ID;
	SET.POS = POS;
	SET.CLASS = CLASS;
	SET.I = I;
	SET.M = M;
	SET.filename = base_name;
end