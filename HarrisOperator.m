imageL = double(imread('teddy/teddyL.pgm'));
imageR = double(imread('teddy/teddyR.pgm'));
groundTruthDP = double(imread('teddy/disp2.pgm'));
[h,w] = size(imageL);
newImgL = calHarrisResponse(imageL,h,w);
newImgR = calHarrisResponse(imageR,h,w);

% non-maximum suppression
% The desired number of 300-500 corners is AFTER thresholding followed by non-maximum suppression.

newImgL = doNMS(newImgL,h,w);
newImgR = doNMS(newImgR,h,w);
figure,imshow(newImgL);
figure,imshow(newImgR);
countL = 0;
countR = 0;
% global sumL
sumL = zeros(h*w, 3);
% global sumR 
sumR = zeros(h*w, 3);
for i=1:h
    for j=1:w
        if newImgL(i,j)>0
            countL = countL+1;
            SAD = calculateSAD(imageL,i,j,h,w);
            sumL(countL,:) = [SAD,i,j];
        end
        if newImgR(i,j)>0
            countR = countR+1;
            SAD = calculateSAD(imageR,i,j,h,w);
            sumR(countR,:) = [SAD,i,j];
        end
    end
end
distanceList = zeros(countL*countR, 4);
for i = 1:countL
    itemL = sumL(i,:);
    minSum = 0;
    disparity = 0;
    for j = 1:countR
        %         1 SAD 2 row 3 col
        itemR = sumR(j,:);
        SAD = abs(itemR(1)-itemL(1));
         d = sqrt((itemR(3)-itemL(3))^2+(itemR(2)-itemL(2)));
%         d = abs(itemR(3)-itemL(3));
%         if j == 1 || minSum>SAD
            minSum = SAD;
            disparity = ceil(d/w*64);
%         end
        %         SAD dif, disparity, row, col
        index = j+(i-1)*countR;
        distanceList(index,:) = [minSum, disparity, itemL(2),itemL(3)];
    end
end

sortedList = sortrows(distanceList);
for ratio = 0.05:0.05:1
    total = countL*countR*ratio;
    badPixelsCount = 0;
    for k = 1:total
        i = sortedList(k,3);
        j = sortedList(k,4);
        d = sortedList(k,2);
        groundTruthD = groundTruthDP(i,j)/4;
        dif = abs(d-groundTruthD);
        if dif>sqrt(2)
            badPixelsCount = badPixelsCount+1;
        end
    end
    correctPixelsCount = total - badPixelsCount;
    fprintf('ratio: %.2f, correct rate:%.2f, correct: %.0f, incorrect: %.0f\n',ratio,correctPixelsCount/total,correctPixelsCount,badPixelsCount);
end

function[newImage] = doNMS(image,h,w)
    newImage = image;
    bound = 1;
    for i=1+bound:h-bound
        for j=1+bound:w-bound
            if image(i,j) > 0
                isNMS = (image(i, j) > image(i-1, j-1)) & (image(i, j) > image(i-1, j))&(image(i, j) > image(i-1, j+1)) &(image(i, j) > image(i, j-1))&(image(i, j) > image(i, j+1))&(image(i, j) > image(i+1, j-1))&(image(i, j) > image(i+1, j))&(image(i, j) > image(i+1, j+1));
                if ~isNMS
                    newImage(i,j) = 0;
                end
            end
        end
    end
end

function [SAD] = calculateSAD(img,i,j,h,w)
    leftBoundary = max(1,j-1);
    upBoundary = max(1,i-1);
    rightBoundary = min(w,j+1);
    bottomBoundary = min(h,i+1);
    SAD = sum(sum(img(upBoundary:bottomBoundary,leftBoundary:rightBoundary)),2);
end

function [newImg] = calHarrisResponse(img,h,w)
    newImg = zeros(h, w);
    % for response calculation, constant between 0.04-0.06
    a = 0.05;
    Threshold = 800000;

    [Ix,Iy] = computeDerivatives(img);
%     [Ix] = doGaussianFilter(Ix);
%     [Iy] = doGaussianFilter(Iy);
    
    Ixx = doGaussianFilter(Ix.*Ix);
    Iyy = doGaussianFilter(Iy.*Iy);
    Ixy = doGaussianFilter(Ix.*Iy);
%     figure,imshow((Ixx));
    
    bound = 1;
    for i=1+bound:h-bound
        for j=1+bound:w-bound
            M = [Ixx(i,j),Ixy(i,j); Ixy(i,j),Iyy(i,j)];
            R = det(M) - a*(trace(M)^2);
%             R = det(M)-(a * trace(M)^2);
%             disp(R);
            if R>Threshold
                newImg(i,j) = R;
            end
        end
    end
end

function [Ix,Iy] = computeDerivatives(sourceImg)
    filerMatrix = [-1,0,1;-1,0,1;-1,0,1];
    Ix = conv2(sourceImg, filerMatrix,'same');
    Iy = conv2(sourceImg, filerMatrix','same');
%     Ix = filter2(filerMatrix,sourceImg);
%     Iy = filter2(filerMatrix',sourceImg);

end

function [image] = doGaussianFilter(sourceImg)
% get 5*5 matrix from http:// homepages.inf.ed.ac.uk/rbf/HIPR2/gsmooth.htm
%     gaussianMatrix = [  1,4,7,4,1
%                         4,16,26,16,4
%                         7,26,41,26,7
%                         4,16,26,16,4
%                         1,4,7,4,1];     
%     image = conv2(sourceImg, gaussianMatrix)/273; ?
% use Laplacian of Gaussian filter 
     h = fspecial('log',5,2);  
     image = filter2(h,sourceImg);
end