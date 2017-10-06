function output_3=id_reader(output_2)
%global rotated_or scaling_fac chip_centroid bboxes
%chip
 rect_3=[output_2.chip_centroid(1)-(0.65*output_2.scaling_fac), output_2.chip_centroid(2)-(0.6*output_2.scaling_fac); output_2.chip_centroid(1)+(0.65*output_2.scaling_fac), output_2.chip_centroid(2)-(0.6*output_2.scaling_fac);output_2.chip_centroid(1)+(0.65*output_2.scaling_fac), output_2.chip_centroid(2)+(0.6*output_2.scaling_fac);output_2.chip_centroid(1)-(0.65*output_2.scaling_fac), output_2.chip_centroid(2)+(0.6*output_2.scaling_fac)];
 BW3 = roipoly(output_2.rotated_or,rect_3(:,1),rect_3(:,2));
 
 % bboxes=[x y width height]
 %BI face
 rect_4=[output_2.bboxes(1), output_2.bboxes(2); output_2.bboxes(1)+output_2.bboxes(3), output_2.bboxes(2); output_2.bboxes(1)+output_2.bboxes(3), output_2.bboxes(2)+output_2.bboxes(4); output_2.bboxes(1), output_2.bboxes(2)+output_2.bboxes(4)];
 BW4=roipoly(output_2.rotated_or,rect_4(:,1),rect_4(:,2));
rotated_or=rgb2gray(output_2.rotated_or);
app_mask=rotated_or.*(BW3+BW4);
figure
imshow(app_mask)

 %chip
centroid_3=regionprops(BW3,'Centroid');
centroid_3=centroid_3.Centroid;
%BI face
centroid_4=regionprops(BW4,'Centroid');
centroid_4=centroid_4.Centroid;

%card
rect_5=[centroid_3(1)-(1.55*output_2.scaling_fac), centroid_3(2)-(2.4*output_2.scaling_fac); centroid_4(1)+(1.2*output_2.scaling_fac), centroid_3(2)-(2.4*output_2.scaling_fac); centroid_4(1)+(1.2*output_2.scaling_fac), centroid_4(2)+(1.6*output_2.scaling_fac); centroid_3(1)-(1.55*output_2.scaling_fac), centroid_4(2)+(1.6*output_2.scaling_fac)];
BW5=roipoly(output_2.rotated_or,rect_5(:,1),rect_5(:,2));
app_mask_final=rotated_or.*(BW5);

%chip
bboxes1=[rect_3(1,1), rect_3(1,2), pdist([rect_3(1,:); rect_3(2,:)]), pdist([rect_3(1,:); rect_3(4,:)])];
%card
bboxes2=[rect_5(1,1), rect_5(1,2), pdist([rect_5(1,:); rect_5(2,:)]), pdist([rect_5(1,:); rect_5(4,:)])];

figure
imshow(rotated_or)
hold on
%ID face
rectangle('Position',output_2.bboxes,'LineWidth',2,'LineStyle','--')
%chip
rectangle('Position',bboxes1,'LineWidth',2,'LineStyle','--')
%card
rectangle('Position',bboxes2,'LineWidth',2,'LineStyle','--')

% detection of text boxes

surname_box=[rect_5(1,1)+(2.4*output_2.scaling_fac), rect_5(1,2)+(1.2*output_2.scaling_fac);rect_5(2,1),rect_5(2,2)+(1.2*output_2.scaling_fac);rect_5(2,1), rect_5(2,2)-(1.8*output_2.scaling_fac);rect_5(1,1)+(2.4*output_2.scaling_fac), rect_5(1,2)+(1.8*output_2.scaling_fac)];
%surname
bboxes3=[surname_box(1,1), surname_box(1,2), pdist([surname_box(1,:); surname_box(2,:)]), pdist([surname_box(1,:); surname_box(4,:)])];

rectangle('Position',bboxes3,'LineWidth',2,'LineStyle','--')


firstname_box=[rect_5(1,1)+(2.4*output_2.scaling_fac), rect_5(1,2)+(2*output_2.scaling_fac);rect_5(2,1),rect_5(2,2)+(2*output_2.scaling_fac);rect_5(2,1), rect_5(2,2)-(2.5*output_2.scaling_fac);rect_5(1,1)+(2.4*output_2.scaling_fac), rect_5(1,2)+(2.5*output_2.scaling_fac)];
%firstname
bboxes4=[firstname_box(1,1), firstname_box(1,2), pdist([firstname_box(1,:); firstname_box(2,:)]), pdist([firstname_box(1,:); firstname_box(4,:)])];

rectangle('Position',bboxes4,'LineWidth',2,'LineStyle','--')

number_box=[rect_5(1,1)+(2.4*output_2.scaling_fac), rect_5(1,2)+(3.5*output_2.scaling_fac);rect_5(2,1)-(4.4*output_2.scaling_fac),rect_5(2,2)+(3.5*output_2.scaling_fac);rect_5(2,1)-(4.4*output_2.scaling_fac), rect_5(2,2)-(4*output_2.scaling_fac);rect_5(1,1)+(2.4*output_2.scaling_fac), rect_5(1,2)+(4*output_2.scaling_fac)];
%number
bboxes5=[number_box(1,1), number_box(1,2), pdist([number_box(1,:); number_box(2,:)]), pdist([number_box(1,:); number_box(4,:)])];

rectangle('Position',bboxes5,'LineWidth',2,'LineStyle','--')

output_3=struct('rotated_or',rotated_or,'bboxes3',bboxes3,'bboxes4',bboxes4,'bboxes5',bboxes5)
end
