function recognizedText=back_read(im_ori)

im_probe=im_ori;
im_probe = rgb2gray(im_probe);
[l,c]=size(im_probe);
se=strel('disk', floor(sqrt(l^2+c^2)/100)); %for the structuring element, the ray of the disk is 1/100 of the diagonal of the image
im_probe = imbothat(im_probe,se);

figure
imshow(im_ori)
hold on

%card
%% this section must be replaced by automatic detection of the card contour
% a section of "if there's no detection of card then there's no card in the
% image, please make a valid acquisition" must be added

[x, y] = getpts;
rect_card=[x, y];
BW1=roipoly(im_probe,rect_card(:,1),rect_card(:,2));
bboxes_card=[rect_card(1,1), rect_card(1,2), pdist([rect_card(1,:); rect_card(2,:)]), pdist([rect_card(1,:); rect_card(4,:)])];

rectangle('Position',bboxes_card,'LineWidth',2,'LineStyle','--')

%bottom information
rect_bottom=[rect_card(1,1),(rect_card(4,2)-rect_card(1,2))*(3/5.3)+rect_card(1,2);rect_card(2,1),(rect_card(3,2)-rect_card(2,2))*(3/5.4)+rect_card(2,2);rect_card(3,1), rect_card(3,2); rect_card(4,1), rect_card(4,2)];
BW2=roipoly(im_probe,rect_card(:,1),rect_card(:,2));
bboxes_bottom=[rect_bottom(1,1), rect_bottom(1,2), pdist([rect_bottom(1,:); rect_bottom(2,:)]), pdist([rect_bottom(1,:); rect_bottom(4,:)])];
BW3=double(roipoly(im_probe,rect_bottom(:,1),rect_bottom(:,2)));
rectangle('Position',bboxes_bottom,'LineWidth',2,'LineStyle','--')

%%
bottom_only=BW3.*im_probe;


%% text read 
im_final = im2bw(bottom_only,graythresh(bottom_only));
I_bottom=imcrop(im_final,bboxes_bottom);
I_bottom = medfilt2(I_bottom);


txt_bottom=ocr(I_bottom,'TextLayout', 'Block', 'CharacterSet', 'QWERTYUIOPASDFGHJKLÇZXCVBNM1234567890<');
recognizedText = txt_bottom.Text;
figure;
imshow(im_probe);
text(600, 150, recognizedText, 'BackgroundColor', [1 1 1]);
end