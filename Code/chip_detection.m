function output_1=chip_detection (filename)
test_im=filename;
im_probe = imread(test_im);
im_probe = imresize(im_probe, 1);

cform = makecform('srgb2lab');
lab_he = applycform(im_probe,cform);

ab = double(lab_he(:,:,2:3));
nrows = size(ab,1);
ncols = size(ab,2);
ab = zscore(reshape(ab,nrows*ncols,2));

nColors = 3;
% % repeat the clustering 3 times to avoid local minima
[cluster_idx, cluster_center] = kmeans(ab,nColors,'distance','sqEuclidean', ...
                                       'Replicates',3,'Display','iter','EmptyAction','drop');
                                  
pixel_labels = reshape(cluster_idx,nrows,ncols);
imshow(pixel_labels,[]), title('image labeled by cluster index');

segmented_images = cell(1,3);
rgb_label = repmat(pixel_labels,[1 1 3]);

for k = 1:nColors
    color = lab_he;
    color(rgb_label ~= k) = 0;
    segmented_images{k} = color;
end

decision = [];

for ii =1:nColors
    cluster = (rgb_label == ii);
    blocks = bwlabel(cluster(:,:,1));
    
    for blockdata = 1:max(blocks(:))
        figure, imagesc(blocks==blockdata)
        data = regionprops((blocks==blockdata),'Area','ConvexArea','Centroid','Eccentricity');
        if data.Area > 1000
            decision(ii,blockdata) = data.ConvexArea/data.Area * data.Eccentricity;
        end
    end
end

decision(decision == 0) = NaN;
[x,y] = find(decision == min(decision(:)));

cluster = (rgb_label == x);
blocks = bwlabel(cluster(:,:,1));
figure, imshow(im_probe);

green = cat(3,zeros(size(im_probe,1),size(im_probe,2)), ones(size(im_probe,1),size(im_probe,2)), zeros(size(im_probe,1),size(im_probe,2))); 
hold on,

h=imshow(green);

hold off

mask = bwconvhull(blocks == y);
mask(mask == 1) = 0.75;

set(h, 'AlphaData', mask);
y=mask;
output_1=struct('mask',mask,'im_probe', im_probe)
end
