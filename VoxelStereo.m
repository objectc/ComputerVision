
resolution = 0.05;
worldCoordList = [];
% for x = -2.5:resolution:2.5
%     for y = -3:resolution:3
%         for z = 0:resolution:2.5
%             point = [x,y,z,1]';
%             worldCoordList = [worldCoordList,point];
%         end
%     end
% end
x = -2.5:resolution:2.5;
y = -3:resolution:3;
z = 0:resolution:2.5;
[xx,yy,zz] = meshgrid(x,y,z);
% voxels = [xx,yy,zz];
worldCoordList = [xx(:) yy(:) zz(:)];
homogeneousCoordList = [worldCoordList ones(size(worldCoordList(:,1)))]';
[listK,listSilhouette,listImage] = readData();
colors = zeros(size(homogeneousCoordList,2),3);
for i = 0:7
    K = listK{i+1};
    silhouetteImage = listSilhouette{i+1};
    originalImage = listImage{i+1};
    coord2DList = K*homogeneousCoordList;
    coord2DList = ceil(rdivide(coord2DList,coord2DList(3,:)));
    count = size(coord2DList,2);
    [h,w] = size(silhouetteImage);
    toRemove = [];
    for j = count:-1:1
        x = coord2DList(1,j);
        y = coord2DList(2,j);
        shouldExcluded = true;
        if x<=w && x>0 && y<=h && y>0
            if silhouetteImage(y,x)>0
                shouldExcluded = false;
                colors(j,:) = originalImage(x,y);
            end
        end
        if shouldExcluded
%             coord2DList(:,j) = [];
            toRemove = [toRemove,j];
        end
    end
    homogeneousCoordList(:,toRemove) = [];
    colors(toRemove,:) = [];
%     coord2DLists{i+1} = coord2DList;
end
leftCount = size(homogeneousCoordList,2);

% voxels = zeros(size(x),size(y),size(z));
voxels = [];
% for i = 1:leftCount
%     x = [x;homogeneousCoordList(1,i)];
%     y = [y;homogeneousCoordList(2,i)];
%     z = [z;homogeneousCoordList(3,i)];
%     s = [s;1];
% %     voxels(x(1),y(1),z(1)) = 1;
% %     disp(['x' x 'y' y 'z' z])
% end
voxels = homogeneousCoordList;
voxels(4,:) = [];
voxels = voxels';

genOutput(voxels,colors);
