function [F F_STR] = get_all_features(SET)

h = waitbar(0,'Computing features... ');
i=0;
total_time = 0;
for id = SET.ID
	tic
		image_file = sprintf('%s%s%03d.png',SET.path,filesep,id);
		mask_file  = sprintf('%s%s%03d_mask.png',SET.path,filesep,id);
		[I M] = read_image(image_file, mask_file);
		[F(id,:) F_STR] = get_features(I,M,SET.POS(id));
	total_time = total_time + toc;
	
	i=i+1;
	waitbar(i/length(SET.ID), h);
end
close(h);
fprintf('Avg. time for loading image and computing features: %.2fs\n',total_time/length(SET.ID));

save features F F_STR
