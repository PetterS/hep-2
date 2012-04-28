function [I M] = read_image(image_file,mask_file)

% PCA
meanI = [ 3.4568 41.4073 0.3621];
comp  = [0.0592 0.9982 0.0006];

I = double(imread(image_file));
[m n three] = size(I);
MI = repmat(reshape(meanI,[1 1 3]),[m n 1]);
I = I - MI;
I = 255*rgb2gray(reshape(1/255*meanI,[1 1 3])) +  sum(I .* repmat(reshape(comp,[1 1 3]),[m n 1]), 3);
I = uint8(I);

M = imread(mask_file);
M=logical(M);
