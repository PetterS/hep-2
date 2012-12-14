function [F, F_STR] = get_all_features(SET)

cache_filename = ['cache' filesep SET.filename '-features.mat'];

if exist(cache_filename, 'file')
	load(cache_filename);
else
	h = waitbar(0, ['Computing ' strrep(cache_filename,'\','\\') '... ']);
	total_time = 0;
	for i = 1:SET.n
	    tic
		[F(i,:), F_STR] = get_features(SET.I{i},SET.M{i},SET.POS(i)); %#ok<AGROW>
		total_time = total_time + toc;
		waitbar(i/length(SET.ID), h);
	end
	close(h);

	fprintf('Avg. time for computing features: %.2fs\n',total_time/length(SET.ID));

	save(cache_filename, 'F', 'F_STR');
end
