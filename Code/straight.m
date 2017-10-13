
test_im='image1.jpg';
close all;
im_original = imread(test_im);
im_original = imresize(im_original, 1);
cform = makecform('srgb2lab');
lab_he = applycform(im_original,cform);
channel_l=im2double(lab_he(:,:,1)); 
channel_a=im2double(lab_he(:,:,2)); 
channel_b=im2double(lab_he(:,:,3)); 
figure;subplot(131); imshow(channel_l, []); title('L*');
subplot(132); imshow(channel_a, []); title('a*');
subplot(133); imshow(channel_b, []); title('b*');
%segmentar canal b* com otsu 
thresh = multithresh(channel_b,2);
mask_1=1-im2double(im2bw(channel_b, thresh(1))); 
mask_1=im2bw(mask_1); 
mask_1=imfill(mask_1,'holes'); 
% figure;imshow(mask_1);
SE=strel('disk',10); 
mask_1=imopen(mask_1,SE); 
mask_1 = bwareafilt(mask_1,1,'largest');
mask_2=bwconvhull(mask_1); 
figure; imshow(mask_1); 
just_ID=channel_l.*im2double(mask_2);
imshow(just_ID,[]); 
% Find corners 
BW=bwboundaries(mask_2,8);
A=BW{1,1}; 
A_1=min(A(:,1));  
A_2=max(A(:,2));
A_3=max(A(:,1)); 
A_4=min(A(:,2)); 
C1=[A_2,A_1]; 
C2=[A_4,A_1]; 
C3=[A_2,A_3]; 
C4=[A_4,A_3]; 
[min_C1, I_C1]=min(sum(abs(bsxfun(@minus,C1,[A(:,2),A(:,1)])),2));
[min_C2, I_C2]=min(sum(abs(bsxfun(@minus,C2,[A(:,2),A(:,1)])),2));
[min_C3, I_C3]=min(sum(abs(bsxfun(@minus,C3,[A(:,2),A(:,1)])),2));
[min_C4, I_C4]=min(sum(abs(bsxfun(@minus,C4,[A(:,2),A(:,1)])),2));
bw_C1=[A(I_C1,2),A(I_C1,1)]; 
bw_C2=[A(I_C2,2),A(I_C2,1)];
bw_C3=[A(I_C3,2),A(I_C3,1)]; 
bw_C4=[A(I_C4,2),A(I_C4,1)]; 
hold on, plot(bw_C1(1),bw_C1(2), 'r*')
hold on, plot(bw_C2(1),bw_C2(2), 'r*')
hold on, plot(bw_C3(1),bw_C3(2), 'r*')
hold on, plot(bw_C4(1),bw_C4(2), 'r*')
hold off 
%perspective correction
X=[bw_C1(1);bw_C2(1);bw_C3(1);bw_C4(1)]; 
Y=[bw_C1(2);bw_C2(2);bw_C3(2);bw_C4(2)]; 
correct_image=perspective_correction(just_ID,X, Y);
figure;imshow(correct_image,[]); 

