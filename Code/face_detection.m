function output_2=face_detection(output_1)
%global mask im_probe rotated_or scaling_fac chip_centroid bboxes
props=regionprops(output_1.mask, 'Orientation', 'MajorAxisLength', 'MinorAxisLength');
if abs(props.Orientation)>80 && abs(props.Orientation)<100
    if props.Orientation<0
        degrees=90;
    else 
        degrees=-90;
    end
    rotated=imrotate(output_1.mask, degrees);
    rotated_or=im2double(imrotate(output_1.im_probe, degrees));
else
    rotated=output_1.mask;
    rotated_or=im2double(output_1.im_probe);
end

props_rot=regionprops(rotated, 'Centroid');

chip_centroid=[props_rot.Centroid(1),props_rot.Centroid(2)];

vert_side=props.MinorAxisLength;
scaling_fac=vert_side/1.2;

 faceDetector = vision.CascadeObjectDetector;
 %ID face
 bboxes = step(faceDetector, rotated_or);
 
 [l,c]=size(bboxes);
 if c>1
     [B,I]=sort(bboxes(:,3),'descend');
     bboxes=bboxes(I(1),:);
 end
   IFaces = insertObjectAnnotation(output_1.im_probe, 'rectangle', bboxes, 'Face');
   figure, imshow(IFaces), title('Detected faces');
output_2=struct('rotated_or',rotated_or,'scaling_fac',scaling_fac,'chip_centroid',chip_centroid,'bboxes',bboxes);
end