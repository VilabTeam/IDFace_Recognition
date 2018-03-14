function varargout = video_gui3(varargin)
%% readme
% VIDEO_GUI3 MATLAB code for video_gui3.fig
%      VIDEO_GUI3, by itself, creates a new VIDEO_GUI3 or raises the existing
%      singleton*.
%
%      H = VIDEO_GUI3 returns the handle to a new VIDEO_GUI3 or the handle to
%      the existing singleton*.
%
%      VIDEO_GUI3('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIDEO_GUI3.M with the given input arguments.
%
%      VIDEO_GUI3('Property','Value',...) creates a new VIDEO_GUI3 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before video_gui3_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to video_gui3_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help video_gui3

% Last Modified by GUIDE v2.5 21-Sep-2017 16:39:41
%%
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @video_gui3_OpeningFcn, ...
                   'gui_OutputFcn',  @video_gui3_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code 3- DO NOT EDIT


% --- Executes just before video_gui3 is made visible.
function video_gui3_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to video_gui3 (see VARARGIN)

% Choose default command line output for video_gui3
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

cla; % Clear overlay graphics.
TurnOnLiveVideo(handles);

% UIWAIT makes video_gui3 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = video_gui3_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
% function pushbutton1_Callback(hObject, eventdata, handles)
% % hObject    handle to pushbutton1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% cla; % Clear overlay graphics.
% TurnOnLiveVideo(handles);
%     return;
    
function TurnOnLiveVideo(handles)
global vidobj;
vidobj=videoinput('winvideo', 1);	% Video camera object.
try
% Bail out if there is no video object class instantiated.
if isempty(vidobj)
   return,
end
% Switch the current graphic axes to handles.axesImage.
% This is where we want the video to go.
axes(handles.axesImage);
% Reset image magnification. Required if you ever displayed an image
% in the axes that was not the same size as your camera image.
hold off;

% Make the aspect ratio of the axes the same as the aspect ratio of the camera.
videoRes = get(vidobj, 'VideoResolution');
numberOfBands = get(vidobj, 'NumberOfBands');
fprintf(1, 'Video resolution = %d wide by %d tall, by %d color channels.\n', videoRes(1), videoRes(2), numberOfBands);
% framePosition = get(handles.axesImage, 'Position');
% frameWidth = (framePosition(4) * videoRes(1)) / videoRes(2);
% framePosition2 = framePosition;
% framePosition2(3) = frameWidth;
% set(handles.axesImage, 'Position', framePosition2);
% drawnow;

% Get the handle to the image in the axes.
% handleToImage = findobj(handles.axesImage, 'Type', 'image');
% This is how the MATLAB example code does in. They don't use findobj()
fprintf(1, 'About to allocate temporary memory...\n');
handleToImage = image( zeros([videoRes(2), videoRes(1),numberOfBands], 'uint8') );
fprintf(1, 'About to call preview...\n');

% Turn on the live video.
preview(vidobj, handleToImage);



fprintf(1, 'Done calling preview.\n');
% Clear it now to prevent "Out of memory errors". This doesn't seem to affect the live preview.
% Even though it's a local variable you can get out of memory errors the next time
% you enter this routine if you don't clear it.
clear('handleToImage');
fprintf(1, 'Done clearing temporary memory.\n');

% The video aspect ratio still seems to be stretched horizontally for some reason, despite resizing the axes.
% Setting axis equal seems to fix it.
axis equal;

% Put hold on so that displaying our bounding box doesn't blow away the image.
hold on;
% Retrieve our x,y coordinates of the bounding box corners.
%GetImageMask(handles);
% They have been previously set elsewhere as global variables.
global maskVerticesXCoordinates;
global maskVerticesYCoordinates;
if ~(isempty(maskVerticesXCoordinates) || isempty(maskVerticesYCoordinates))
% If the bounding box coordinates exist,
% plot the bounding box over the live video.
plot(maskVerticesXCoordinates, maskVerticesYCoordinates);
end

% stoppreview(vidobj);
catch ME
errorMessage = sprintf('Error in function TurnOnLiveVideo.\n\nErrorMessage:\n%s', ME.message);
%set(handles.txtInfo, 'string', errorMessage);
uiwait(warndlg(errorMessage));
end

% stoppreview(vidobj);
    return; % from TurnOnLiveVideo



% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global vidobj;	% Video camera object.
if isempty(vidobj)
    return
end
snappedImage = SnapImage(handles);

%%%%%%%%%%%%%%%%%
id_read(snappedImage)
%%%%%%%%%%%%%%%%%


return;

function snappedImage = SnapImage(handles)
% Declare imgOriginal. It might be filled with values here.
global imgOriginal;	% Declare global so that other functions can seeit, if they also declare it global.
global vidobj;	% Video camera object.
if isempty(vidobj), return, end
try
snappedImage = getsnapshot(vidobj);
axes(handles.axesImage);
hold off;
axis auto;
imshow(snappedImage, 'InitialMagnification', 'fit');
grayImage = rgb2gray(snappedImage);

% Just for fun, let's get its histogram.
[pixelCount grayLevels] = imhist(grayImage);
axes(handles.axesPlot);
bar(pixelCount);
title('Histogram of image');
xlim([0 grayLevels(end)]); % Scale x axis manually.

imgOriginal = snappedImage;

catch ME
errorMessage = sprintf('Error in function btnPreviewVideo_Callback.\nError Message:\n%s', ME.message);
%set(handles.txtInfo, 'string', errorMessage);
%msgboxw(errorMessage);
end


% --- Executes during object creation, after setting all properties.
function axesImage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axesImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axesImage
