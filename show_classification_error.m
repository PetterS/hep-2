function i = show_classification_error(SET,id,classified,prob)
figure()

filename = sprintf('%s%s%03d%s',SET.path,filesep,id,'.png');
i = histeq(rgb2gray(imread(filename)));

w=100;
i = repmat(imresize(i, [w w]), [1 1 3]);
i = rendertext(i,num2str(classified),   [255 0 0], [10 25],'ovr','mid');
i = rendertext(i,num2str(SET.CLASS(id)),[0 255 0], [10 75],'ovr','mid');

str = sprintf('%.0f/',100*prob(classified));
i = rendertext(i,str,   [255 0 0], [100 25],'ovr','mid');
str = sprintf('%.0f/',100*prob(SET.CLASS(id)));
i = rendertext(i,str,[0 255 0], [100 75],'ovr','mid');


imshow(i)

types = {'homogeneous','coarse speckled','fine speckled','nucleolar','centromere','cytoplasmatic'};

title(sprintf('ID: %d, LABEL: %s (%d) CORRECT: %s (%d)', ...
    id, types{classified},classified, types{SET.CLASS(id)}, SET.CLASS(id)));

fprintf('ID: %d, LABEL: %s (%d) P=%.1f%% CORRECT: %s (%d) P=%.1f%%\n', ...
    id, types{classified},classified,100*prob(classified),...
    types{SET.CLASS(id)}, SET.CLASS(id), 100*prob(SET.CLASS(id)));
fprintf('    P = [');
fprintf('%.1f%% ',100*prob);
fprintf(']\n');