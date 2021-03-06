close all

%% detection of the chip

test_im = 'ana_costa_BI.jpg';
im_probe = imread(test_im);
im_probe = im2double(imresize(im_probe, 1));

%%face detection
 faceDetector = vision.CascadeObjectDetector;
 bboxes = step(faceDetector, im_probe);
 
 if isempty(bboxes) 
     fprintf("Proceeding to read back of the card");
 else
     
 
 [l,c]=size(bboxes);
 if c>1
     [B,I]=sort(bboxes(:,3),'descend');
     bboxes=bboxes(I(1),:);
 end
   IFaces = insertObjectAnnotation(im_probe, 'rectangle', bboxes, 'Face');
   figure, imshow(IFaces), title('Detected faces');
   
   %% chip detection
   
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

props=regionprops(mask, 'Centroid', 'MinorAxisLength');
chip_centroid=[props.Centroid(1),props.Centroid(2)];

vert_side=props.MinorAxisLength;
scaling_fac=vert_side/1.2;

 %% 
 %chip
 rect_3=[chip_centroid(1)-(0.65*scaling_fac), chip_centroid(2)-(0.6*scaling_fac); chip_centroid(1)+(0.65*scaling_fac), chip_centroid(2)-(0.6*scaling_fac);chip_centroid(1)+(0.65*scaling_fac), chip_centroid(2)+(0.6*scaling_fac);chip_centroid(1)-(0.65*scaling_fac), chip_centroid(2)+(0.6*scaling_fac)];
 BW3 = roipoly(im_probe,rect_3(:,1),rect_3(:,2));
 
 % bboxes=[x y width height]
 %BI face
 rect_4=[bboxes(1), bboxes(2); bboxes(1)+bboxes(3), bboxes(2); bboxes(1)+bboxes(3), bboxes(2)+bboxes(4); bboxes(1), bboxes(2)+bboxes(4)];
 BW4=roipoly(im_probe,rect_4(:,1),rect_4(:,2));
app_mask=im_probe.*(BW3+BW4);
figure
imshow(app_mask)

 %chip
centroid_3=regionprops(BW3,'Centroid');
centroid_3=centroid_3.Centroid;
%BI face
centroid_4=regionprops(BW4,'Centroid');
centroid_4=centroid_4.Centroid;

dist_chip_face=ceil(centroid_3-centroid_4);

if -350<dist_chip_face(1)<-250
    if -40<dist_chip_face(2)<-80
        
        
%card
rect_5=[centroid_3(1)-(1.55*scaling_fac), centroid_3(2)-(2.4*scaling_fac); centroid_4(1)+(1.2*scaling_fac), centroid_3(2)-(2.4*scaling_fac); centroid_4(1)+(1.2*scaling_fac), centroid_4(2)+(1.6*scaling_fac); centroid_3(1)-(1.55*scaling_fac), centroid_4(2)+(1.6*scaling_fac)];
BW5=roipoly(im_probe,rect_5(:,1),rect_5(:,2));
app_mask_final=im_probe.*(BW5);


%chip
bboxes1=[rect_3(1,1), rect_3(1,2), pdist([rect_3(1,:); rect_3(2,:)]), pdist([rect_3(1,:); rect_3(4,:)])];
%card
bboxes2=[rect_5(1,1), rect_5(1,2), pdist([rect_5(1,:); rect_5(2,:)]), pdist([rect_5(1,:); rect_5(4,:)])];

figure
imshow(im_probe)
hold on
%ID face
rectangle('Position',bboxes,'LineWidth',2,'LineStyle','--')
%chip
rectangle('Position',bboxes1,'LineWidth',2,'LineStyle','--')
%card
rectangle('Position',bboxes2,'LineWidth',2,'LineStyle','--')

% detection of text boxes

surname_box=[rect_5(1,1)+(2.4*scaling_fac), rect_5(1,2)+(1.2*scaling_fac);rect_5(2,1),rect_5(2,2)+(1.2*scaling_fac);rect_5(2,1), rect_5(2,2)-(1.8*scaling_fac);rect_5(1,1)+(2.4*scaling_fac), rect_5(1,2)+(1.8*scaling_fac)];
%surname
bboxes3=[surname_box(1,1), surname_box(1,2), pdist([surname_box(1,:); surname_box(2,:)]), pdist([surname_box(1,:); surname_box(4,:)])];

rectangle('Position',bboxes3,'LineWidth',2,'LineStyle','--')


firstname_box=[rect_5(1,1)+(2.4*scaling_fac), rect_5(1,2)+(2*scaling_fac);rect_5(2,1),rect_5(2,2)+(2*scaling_fac);rect_5(2,1), rect_5(2,2)-(2.5*scaling_fac);rect_5(1,1)+(2.4*scaling_fac), rect_5(1,2)+(2.5*scaling_fac)];
%firstname
bboxes4=[firstname_box(1,1), firstname_box(1,2), pdist([firstname_box(1,:); firstname_box(2,:)]), pdist([firstname_box(1,:); firstname_box(4,:)])];

rectangle('Position',bboxes4,'LineWidth',2,'LineStyle','--')

number_box=[rect_5(1,1)+(2.4*scaling_fac), rect_5(1,2)+(3.5*scaling_fac);rect_5(2,1)-(4.4*scaling_fac),rect_5(2,2)+(3.5*scaling_fac);rect_5(2,1)-(4.4*scaling_fac), rect_5(2,2)-(4*scaling_fac);rect_5(1,1)+(2.4*scaling_fac), rect_5(1,2)+(4*scaling_fac)];
%number
bboxes5=[number_box(1,1), number_box(1,2), pdist([number_box(1,:); number_box(2,:)]), pdist([number_box(1,:); number_box(4,:)])];

rectangle('Position',bboxes5,'LineWidth',2,'LineStyle','--')

    end
end
 end