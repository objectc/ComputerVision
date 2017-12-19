clc; clear ALL;
%% source image read
sourceImg = imread('basketball-court.ppm');
%define destination image height and width
destH = 940;
destW = 500;
destImg = zeros(destH,destW);

%% Correspondences
% in order to warp the basketball court only, select the 4 vertices of the
% court from the source image
pointsSrc = [
        22    247   403   279
        195    52    75   275
        1     1     1     1
        ];
% corresponded in the destination
pointsDest = [
                1   destH   destH   1
                1   1       destW   destW
                1   1       1       1
                ];


%% DLT algorithm

%% Normalize matrix for source and destination image
T1=[size(pointsSrc,1)+size(pointsSrc,2) 0 size(pointsSrc,2)/2;
    0 size(pointsSrc,1)+size(pointsSrc,2) size(pointsSrc,1)/2;
    0 0 1];
T2=[destW+destH 0 destW/2;
    0 destW+destH destH/2;
    0 0 1];
p1 = T1*pointsSrc;
p2 = T2*pointsDest;


%% Generate A according correspondences

A = zeros(8,9);

for i = 1:4
    A(2*i-1,:) = [0 0 0 -p2(3,i)*p1(:,i)' p2(2,i).*p1(:,i)'];
    A(2*i,:) = [p2(3,i)*p1(:,i)' 0 0 0 -p2(1,i).*p1(:,i)'];
end

%% svd to generate H
[U,S,V] = svd(A);
h = V(:,9);
% generate H
H = [
        h(1) h(2) h(3)
        h(4) h(5) h(6)
        h(7) h(8) h(9)
    ];

%% Denormalization
% '\' means inverse, inv function will cause accurate warning
H = T2\H*T1;

%% Applying the transformation to the source image
sourceImg = double(sourceImg);
for i = 1:size(destImg,1)
    for j = 1:size(destImg,2)
        % transpose     
        destPoint = [i j 1]';
        %inverse
        sourcePoint = H\destPoint;
        % divide the the last row, make it to 1
        sourcePoint = sourcePoint/sourcePoint(3);
        
        
%% Get color from source image and use bilinear interpolation alg to render the output image
        %make sure the point is inside the picture
        if (sourcePoint(1) > 0) && (sourcePoint(2) > 0) && (sourcePoint(1) <= size(sourceImg,2)) && (sourcePoint(2) <= size(sourceImg,1))
%             bilinear interpolation
            pointRGB = bilinearInterpolation(sourceImg,sourcePoint);
            destImg(i,j,1) = pointRGB(1,1,1);
            destImg(i,j,2) = pointRGB(1,1,2);
            destImg(i,j,3) = pointRGB(1,1,3);
        end


        
    end
end
%% Output
figure, imshow(destImg);
imwrite(destImg, 'overlooking.png');

%% Bilinear Interpolation Algorithm
% functions should be define in the bottom of the file
function [pointRGB] = bilinearInterpolation(sourceImg,point)
    x = point(1);
    y = point(2);
    b = y-floor(y);
    a = x-floor(x);
    f00 = sourceImg(floor(y), floor(x),:);
    f10 = sourceImg(floor(y), ceil(x),:);
    f01 = sourceImg(ceil(y), floor(x),:);
    f11 = sourceImg(ceil(y), ceil(x),:);
    pointRGB = (f00*(1-a)*(1-b)+f10*a*(1-b)+f01*(1-a)*b+f11*a*b)/255;   
end


