% Load images.
imageDir = ['/Users/tr3m431/Desktop/zucrow stuff/images/imgset2' ...
    ''];
scene = imageDatastore(imageDir);

% Display images to be stitched.
montage(scene.Files);

% Read the first image from the image set.
I = readimage(scene, 1);

% Initialize features for I(1).
grayImage = im2gray(I);
points = detectSURFFeatures(grayImage);
[features, points] = extractFeatures(grayImage, points);

% Initialize all the transformations to the identity matrix. 
% Note that the projective transformation is used here because the images are fairly
% close to the camera. For scenes captured from a further distance, you can use
% affine transformations.
numImages = numel(scene.Files);
tforms(numImages) = projective2d;

% Initialize variable to hold image sizes.
imageSize = zeros(numImages, 2);

% Iterate over remaining image pairs
for n = 2:numImages
    % Store points and features for I(n-1).
    pointsPrevious = points;
    featuresPrevious = features;
      
    % Read I(n).
    I = readimage(scene, n);
  
    % Convert image to grayscale.
    grayImage = im2gray(I);   
  
    % Save image size.
    imageSize(n,:) = size(grayImage);
  
    % Detect and extract SURF features for I(n).
    points = detectSURFFeatures(grayImage);   
    [features, points] = extractFeatures(grayImage, points);
    
    % Find correspondences between I(n) and I(n-1).
    indexPairs = matchFeatures(features, featuresPrevious, 'Unique', true);
    
    % Check if there are enough matched points
    if size(indexPairs, 1) < 4
        warning(['Not enough matched points between image ', num2str(n-1), ' and image ', num2str(n)]);
        continue; % Skip to the next image pair
    end
     
    matchedPoints = points(indexPairs(:,1), :);
    matchedPointsPrev = pointsPrevious(indexPairs(:,2), :);       
  
    % Estimate the transformation between I(n) and I(n-1).
    tforms(n) = estimateGeometricTransform2D(matchedPoints, matchedPointsPrev,...
        'projective', 'Confidence', 99.9, 'MaxNumTrials', 2000);
  
    % Compute T(1) * T(2) * ... * T(n-1) * T(n).
    tforms(n).T = tforms(n-1).T * tforms(n).T;
end

% Initialize xlim and ylim arrays with the correct size
% Initialize xlim and ylim arrays with the correct size
numTforms = numel(tforms);
fprintf("numTforms= %d\n", numTforms);
xlim = zeros(numTforms-1, 2);
ylim = zeros(numTforms-1, 2);

% fprintf("numTforms= %d\n", numTforms);
% Compute the output limits for each transformation.
for i = 1:numTforms          
    % fprintf("i= %d\n", i);
    % Check if the index exceeds the number of transformations
    if i > 3
        break;
    end
    
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 imageSize(i,2)], [1 imageSize(i,1)]);    
end

avgXLim = mean(xlim, 2);
[~,idx] = sort(avgXLim);
centerIdx = floor((numel(tforms)+1)/2);
centerImageIdx = idx(centerIdx);

Tinv = invert(tforms(centerImageIdx));
for i = 1:numel(tforms)    
    tforms(i).T = Tinv.T * tforms(i).T;
end

for i = 1:numel(tforms)-1
    % fprintf("i= %d\n", i);
    if i > 3
        break;
    end
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 imageSize(i,2)], [1 imageSize(i,1)]);
end

maxImageSize = max(imageSize);

% Find the minimum and maximum output limits. 
xMin = min([1; xlim(:)]);
xMax = max([maxImageSize(2); xlim(:)]);

yMin = min([1; ylim(:)]);
yMax = max([maxImageSize(1); ylim(:)]);

% Width and height of panorama.
width  = round(xMax - xMin);
height = round(yMax - yMin);

% Initialize the "empty" panorama.
panorama = zeros([height width 3], 'like', I);

blender = vision.AlphaBlender('Operation', 'Binary mask', ...
    'MaskSource', 'Input port');  

% Create a 2-D spatial reference object defining the size of the panorama.
xLimits = [xMin xMax];
yLimits = [yMin yMax];
panoramaView = imref2d([height width], xLimits, yLimits);

% Create the panorama.
for i = 1:numImages
    
    I = readimage(scene, i);   
   
    % Transform I into the panorama.
    warpedImage = imwarp(I, tforms(i), 'OutputView', panoramaView);
                  
    % Generate a binary mask.    
    mask = imwarp(true(size(I,1),size(I,2)), tforms(i), 'OutputView', panoramaView);
    
    % Overlay the warpedImage onto the panorama.
    panorama = step(blender, panorama, warpedImage, mask);
end

figure
imshow(panorama)
