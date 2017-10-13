function id_read(handles)

% set of algorithms triggered by the start of the segmentation process
% 1) check whether the front or back side of the card is presented to the
%    webcam stream
% 2) segment face and chip from the front side OR
% 3) segment MRZ region from the back side
% 4) perform OCR on the ROIs of meaningful textboxes

% read image from video stream
global imgOriginal;	% declare global so that other functions can see it
global vidobj;	% video camera object.
if isempty(vidobj), return, end
try
    snappedImage = getsnapshot(vidobj); % get current frame
    axes(handles.axesImage);
    hold off;
    axis auto;
    imgOriginal = snappedImage;
catch ME
    errorMessage = sprintf('Error in function btnPreviewVideo_Callback.\nError Message:\n%s', ME.message);
end

im_probe = im2double(imresize(snappedImage, 1));    % change imresize parameter if there is need to adapt for higher resolutions

% face detection using Viola-Jones algorithm
faceDetector = vision.CascadeObjectDetector;
bboxes = step(faceDetector, im_probe);

% front or back check (if face and chip -> front, if none -> back)
if isempty(bboxes)
    
    % if no faces are detected it is considered that the back of the card
    % is presented to the webcam (no faces is not a possibility in the
    % proposed algorithm, due to the existence of an external controller
    
    fprintf('Proceeding to read back of the card');
    text_rec = back_read(im_probe);
    
else
    
    % if one face only is detected show it on the video
    
    [~,c] = size(bboxes);
    if c>1
        
        % if multiple faces are detected for a single frame, consider only
        % the best one. we consider that the external controller guarantees
        % that only one face is detected but insert this constraint in the
        % case something goes wrong...
        
        [~,I] = sort(bboxes(:,3),'descend');
        bboxes = bboxes(I(1),:);
    end
    
    % plot face detection results (uncomment if wanted for debug)
    IFaces = insertObjectAnnotation(im_probe, 'rectangle', bboxes, 'Face');
    imshow(IFaces)
    
    % chip detection
    cform = makecform('srgb2lab');
    lab_he = applycform(im_probe,cform);
    
    % normalize the A/B color channels to zero mean and unit co-variance
    ab = double(lab_he(:,:,2:3));   % consider only the A and B channels
    nrows = size(ab,1);
    ncols = size(ab,2);
    ab = zscore(reshape(ab,nrows*ncols,2));
    
    nColors = 3;    % Consider that the card is composed mainly of three colored regions, variable parameter
    
    % if not time constraints exist the clustering can be repeated multiple times
    % to avoid local minima. here we consider a single run
    
    k = 1;
    [cluster_idx, ~] = kmeans(ab,nColors,'distance','sqEuclidean', ...
        'Replicates',k,'Display','off','EmptyAction','drop');
    
    pixel_labels = reshape(cluster_idx,nrows,ncols);
    
    segmented_images = cell(1,3);
    rgb_label = repmat(pixel_labels,[1 1 3]);
    
    for k = 1:nColors
        color = lab_he;
        color(rgb_label ~= k) = 0;
        segmented_images{k} = color;
    end
    
    decision = [];
    
    for ii = 1:nColors
        cluster = (rgb_label == ii);
        cluster = imopen(cluster, strel('disk',10));
        blocks = bwlabel(cluster(:,:,1));
        
        
        for blockdata = 1:max(blocks(:))
            data = regionprops((blocks==blockdata),'Area','ConvexArea','Centroid','Eccentricity');
            
            
            if data.Area > 0.5*bboxes(3)^2 && data.Area < 1.5*bboxes(3)^2  % empirically defined knowing the size of the detected face
                decision(ii,blockdata) = data.ConvexArea/data.Area * data.Eccentricity;
            end
        end
    end
    
    decision(decision == 0) = NaN;
    [x,y] = find(decision == min(decision(:)));
    
    cluster = (rgb_label == x);
    cluster = imopen(cluster, strel('disk',10));
    blocks = bwlabel(cluster(:,:,1));
    
    % uncomment to see results of chip detection
    
%     green = cat(3,zeros(size(im_probe,1),size(im_probe,2)), ones(size(im_probe,1),size(im_probe,2)), zeros(size(im_probe,1),size(im_probe,2)));
    hold on,
    
%     h=imshow(green);
    
    
    
    mask = bwconvhull(blocks == y);
%     mask = imdilate(mask, strel('disk',5));
%     aux_mask = mask;
%     mask(mask == 1) = 0.75;
%     
%     set(h, 'AlphaData', mask);
    
    
    % find corners of the oriented bounding box 
    BW = bwboundaries(mask,8);
    A = BW{1,1};
    orientedb = orientedBox(A);
    orientedb = [orientedb(2),orientedb(1),orientedb(3),orientedb(4),...
        90-orientedb(5)];   % correct orientation to image axis system
    [vx,vy] = drawOrientedBox(orientedb, 'color', 'g');

    X=[vx(1);vx(2);vx(3);vx(4)];
    Y=[vy(1);vy(2);vy(3);vy(4)];
%     correct_image = perspective_correction(snappedImage, X, Y);
    correct_image = imrotate(snappedImage, orientedb(5));
    figure;imagesc(correct_image);    
    
    % Define centroid coordinates
    props=regionprops(mask, 'Centroid', 'MinorAxisLength');
    chip_centroid = [props.Centroid(1),props.Centroid(2)];
    face_centroid = [bboxes(1)+bboxes(3)/2, bboxes(2)+bboxes(3)/2];
    
    % Compute scaling factor to cm. Chip minor axis is 1.2cm
    vert_side=props.MinorAxisLength;
    scaling_fac=vert_side/1.2;
    
    % Calculate Euclidean distance between chip candidate and face
    distance = pdist([chip_centroid; face_centroid],'euclidean')/scaling_fac
    
    % Define masks for text box detection (IMPROVE)
    % Chip
    rect_3 = [chip_centroid(1)-(0.65*scaling_fac), chip_centroid(2)-(0.6*scaling_fac); chip_centroid(1)+(0.65*scaling_fac), chip_centroid(2)-(0.6*scaling_fac);chip_centroid(1)+(0.65*scaling_fac), chip_centroid(2)+(0.6*scaling_fac);chip_centroid(1)-(0.65*scaling_fac), chip_centroid(2)+(0.6*scaling_fac)];
    
    % Face
    rect_4 = [bboxes(1), bboxes(2); bboxes(1)+bboxes(3), bboxes(2); bboxes(1)+bboxes(3), bboxes(2)+bboxes(4); bboxes(1), bboxes(2)+bboxes(4)];
    
    % Check if the distance between centroids falls within the layout
    if distance <= 6 && distance >= 4.75
        
        %card
        rect_5=[chip_centroid(1)-(1.55*scaling_fac), chip_centroid(2)-(2.4*scaling_fac); face_centroid(1)+(1.2*scaling_fac), chip_centroid(2)-(2.4*scaling_fac); face_centroid(1)+(1.2*scaling_fac), face_centroid(2)+(1.6*scaling_fac); chip_centroid(1)-(1.55*scaling_fac), face_centroid(2)+(1.6*scaling_fac)];
        BW5 = roipoly(im_probe,rect_5(:,1),rect_5(:,2));
        
        
        %chip
        bboxes1=[rect_3(1,1), rect_3(1,2), pdist([rect_3(1,:); rect_3(2,:)]), pdist([rect_3(1,:); rect_3(4,:)])];
        %card
        bboxes2=[rect_5(1,1), rect_5(1,2), pdist([rect_5(1,:); rect_5(2,:)]), pdist([rect_5(1,:); rect_5(4,:)])];
        
        
        %ID face
        rectangle('Position',bboxes,'LineWidth',2,'LineStyle','--','EdgeColor','y')
        %chip
        rectangle('Position',bboxes1,'LineWidth',2,'LineStyle','--','EdgeColor','g')
        %card
        %         rectangle('Position',bboxes2,'LineWidth',2,'LineStyle','--')
        
        % detection of text boxes
        
        surname_box=[rect_5(1,1)+(2.3*scaling_fac), rect_5(1,2)+(1.35*scaling_fac);...
            rect_5(2,1)-(0.5*scaling_fac),rect_5(2,2)+(1.35*scaling_fac);...
            rect_5(2,1)-(0.5*scaling_fac), rect_5(2,2)-(1.8*scaling_fac);...
            rect_5(1,1)+(2.3*scaling_fac), rect_5(1,2)+(1.8*scaling_fac)];
        %surname
        bboxes3=[surname_box(1,1), surname_box(1,2), pdist([surname_box(1,:); surname_box(2,:)]), pdist([surname_box(1,:); surname_box(4,:)])];
        rect_surname = [bboxes3(1),bboxes3(2);...
            bboxes3(1)+bboxes3(3),bboxes3(2);
            bboxes3(1)+bboxes3(3),bboxes3(2)+bboxes3(4);
            bboxes3(1),bboxes3(2)+bboxes3(4)];
        BW_surname = roipoly(im_probe,...
            rect_surname(:,1), rect_surname(:,2));
        
        
        surname = im_probe .* BW_surname;
        
        %         I_bottom = adapthisteq(rgb2gray(imcrop(surname,bboxes3)));   % needs adjusting because of the visual glitches regarding the color
        %         I_bottom(1,:) = []; I_bottom(:,1) = [];
        %         I_bottom(end,:) = []; I_bottom(:,end) = [];
        %         I_bottom = imadjust(I_bottom);
        %                 im_final = imbinarize(I_bottom,0.25);
        %         graythresh(I_bottom)
        %                 im_final = imclose(im_final, strel('square',2));
        
        I_surname = rgb2gray(imcrop(surname,bboxes3));
        [l,~] = graythresh(I_surname)
        I_bin = imbinarize(I_surname,l);
        I_bin(1,:) = [];
        I_bin(:,1) = [];
        I_bin(end,:) = [];
        I_bin(:,end) = [];
        im_final = medfilt2(I_bin);
        
        
        txt_bottom=ocr(im_final,'TextLayout', 'Line', 'CharacterSet', 'QWERTYUIOPASDFGHJKLZXCVBNM');
        recognizedText = txt_bottom.Text
        recconf = txt_bottom.CharacterConfidences'
        recognizedText(recconf < 0.75) = '*';
        text(600, 150, recognizedText, 'BackgroundColor', [1 1 1]);
        
        rectangle('Position',bboxes3,'LineWidth',2,'LineStyle','--')
        
        
        firstname_box=[rect_5(1,1)+(2.4*scaling_fac), rect_5(1,2)+(2*scaling_fac);rect_5(2,1),rect_5(2,2)+(2*scaling_fac);rect_5(2,1), rect_5(2,2)-(2.5*scaling_fac);rect_5(1,1)+(2.4*scaling_fac), rect_5(1,2)+(2.5*scaling_fac)];
        %firstname
        bboxes4=[firstname_box(1,1), firstname_box(1,2), pdist([firstname_box(1,:); firstname_box(2,:)]), pdist([firstname_box(1,:); firstname_box(4,:)])];
        
        rectangle('Position',bboxes4,'LineWidth',2,'LineStyle','--')
        
        number_box=[rect_5(1,1)+(2.4*scaling_fac), rect_5(1,2)+(3.5*scaling_fac);...
            rect_5(2,1)-(4.2*scaling_fac),rect_5(2,2)+(3.5*scaling_fac);...
            rect_5(2,1)-(4.2*scaling_fac), rect_5(2,2)-(4*scaling_fac);...
            rect_5(1,1)+(2.4*scaling_fac), rect_5(1,2)+(4*scaling_fac)];
        %number
        bboxes5=[number_box(1,1), number_box(1,2), pdist([number_box(1,:); number_box(2,:)]), pdist([number_box(1,:); number_box(4,:)])];
        
        rectangle('Position',bboxes5,'LineWidth',2,'LineStyle','--')
        hold off
    else
        fprintf('No ID card detected');
        %         text_rec=back_read(im_probe);
    end
end