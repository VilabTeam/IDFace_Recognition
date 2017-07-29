function info=text_reader(output_3)
im_final = im2bw(output_3.rotated_or,graythresh(output_3.rotated_or));
I_surname=imcrop(im_final,output_3.bboxes3);
txt_surname=ocr(I_surname,'TextLayout', 'Block');
I_firstname=imcrop(im_final,output_3.bboxes4);
txt_firstname=ocr(I_firstname,'TextLayout', 'Block');
I_id=imcrop(im_final,output_3.bboxes5);
txt_id=ocr(I_id,'TextLayout', 'Block');
info=struct('Name',strcat(txt_firstname.Text,' ', txt_surname.Text),'ID',txt_id.Text);
end
