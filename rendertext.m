%by Davide Di Gloria 
%with the great contribution of Franz-Gerold Url
%
%Render RGB text over RGB or grayscale images
%
%out=rendertext(target, text, color, pos, mode1, mode2)
%
%target ... MxNx3 or MxN matrix (grayscale will be converted to RGB)
%text   ... string (NO LINE FEED SUPPORT)
%color  ... vector in the form [r g b] 0-255
%pos    ... position (r,c) 
%
%optional arguments: (default is 'ovr','left')
%mode1  ... 'ovr' to overwrite, 'bnd' to blend text over image
%mode2  ... text aligment 'left', 'mid'  or 'right'.
%
%out    ... has same size of target
%
%example:
%
%in=imread('football.jpg');
%out=rendertext(in,'OVERWRITE mode',[0 255 0], [1, 1]);
%out=rendertext(out,'BLEND mode',[255 0 255], [30, 1], 'bnd', 'left');
%out=rendertext(out,'left',[0 0 255], [101, 150], 'ovr', 'left');
%out=rendertext(out,'mid',[0 0 255], [130, 150], 'ovr', 'mid');
%out=rendertext(out,'right',[0 0 255], [160, 150], 'ovr', 'right');
%imshow(out)

function out=rendertext(target, text, color, pos, mode1, mode2)

if nargin == 4
    mode1='ovr';
    mode2='left';
end

dim = length(size(target));
if dim == 2
  target = cat(3, target, target, target);
end

pos = uint16(pos);

r=color(1);
g=color(2);
b=color(3);

n=uint16(numel(text));

base=uint8(1-logical(imread('chars.bmp')));
base=cat(3, base*r, base*g, base*b);

table='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890''!"$%&/()=?^+,.-<\|;:_>?*@#[]{} ';

coord(2,n)=0;
for i=1:n    
  coord(:,i)= [0 find(table == text(i))-1];
end

m = floor(coord(2,:)/26);
coord(1,:) = m*20+1;
coord(2,:) = (coord(2,:)-m*26)*13+1;

overlay = uint8(zeros(20,n*13,3));
for i=1:n
  overlay(:, (13*i-12):(i*13), :) = imcrop(base,[coord(2,i) coord(1,i) 12 19]);
end

dim = uint16(size(overlay(:,:,1)));

if strcmp(mode2, 'mid') == 1
  pos = pos-dim/2+1;
elseif strcmp(mode2, 'right') == 1
  pos = pos-dim+1;
elseif strcmp(mode2, 'left') ~= 1
  error('%s not allowed as alignment specifier. (Allowed: left, mid  or right)', mode2)
end

dim_img = uint16(size(target(:,:,1)));
if sum(dim > dim_img) ~= 0
    error('The text is too long for this image.')
end 

pos = min(dim_img,pos+dim)-dim;

area_y = pos(1):(pos(1)+size(overlay,1)-1);
area_x = pos(2):(pos(2)+size(overlay,2)-1);

if strcmp(mode1, 'ovr') == 1
  target(area_y, area_x,:)=overlay; 
elseif strcmp(mode1,'bnd') == 1
	%Petter mod
  bg = target(area_y, area_x, :);
  fg = overlay;
  for d=1:3
	bgd=bg(:,:,d);
	bgd(any(overlay~=0,3)) = 0;
	bg(:,:,d)=bgd;
  end
  target(area_y, area_x, :) = fg+bg;
else
  error('%s is a wrong overlay mode (allowed: ovr or bnd)', mode1)
end

out=target;
