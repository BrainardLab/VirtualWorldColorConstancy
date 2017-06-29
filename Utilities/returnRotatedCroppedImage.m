function croppedImage = returnRotatedCroppedImage(maskImage, radianceImage, angleOfRotation, cropImageHalfSize)
 
%% Take a mask and radiance image and a given angle of rotation and return
% a cropped image
%
% croppedImage = returnRotatedCroppedImage(maskImage, radianceImage, ...
%               angleOfRotation, cropImageHalfSize);
% % Input
% maskImage is a M x N boolean matrix with ones at the target locations
% radianceImage is a M x N x P matrix
% angleOfRotation the angle in degree over which the image is rotated
% cropImageHalfSize gives the half size of the cropped image. The cropped
% image size is (2*cropImageHalfSize+1)
%
% % Output
% croppedImage: The cropped part of the rotated image, It has the size
% QxQxP, where Q = (2*cropImageHalfSize+1)
%
% Written by VS: Jun 28 2017
 
% Rotate the mask image and find the center pixel
rotatedMaskImage = imrotate(maskImage,angleOfRotation,'bilinear','crop');
[tempR, tempC] = findTargetCenter(rotatedMaskImage); % rotated image target center
                                                        % pixel row and column
% Rotate the radiance image
rotatedRadianceImage = zeros(size(radianceImage));
for iterSpectra = 1:size(radianceImage,3)
    rotatedRadianceImage(:,:,iterSpectra) = imrotate(radianceImage(:,:,iterSpectra),...
        angleOfRotation,'nearest','crop');
end
 
% Use the center point and the rotated image to get the cropped image
croppedImage = rotatedRadianceImage(tempR-cropImageHalfSize:1:tempR+cropImageHalfSize,...
    tempC-cropImageHalfSize:1:tempC+cropImageHalfSize,:);
 
% figure;
% subplot(2,3,1); imagesc(maskImage); axis square;
% subplot(2,3,2); imagesc(rotatedMaskImage); axis square;
% subplot(2,3,3); imagesc(sum(radianceImage,3)); axis square;
% subplot(2,3,4); imagesc(sum(rotatedRadianceImage,3)); axis square;
% subplot(2,3,5); imagesc(sum(croppedImage,3)); axis square;