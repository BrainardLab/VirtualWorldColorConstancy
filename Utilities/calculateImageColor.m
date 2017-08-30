function imageColor = calculateImageColor(XYZImage)
% imageColor = calculateImageColor(XYZImage)
%
% Usage: 
%     imageColor = calculateImageColor(XYZImage)
%
% Description:
%     This function calcualtes the luminance, chroma and the hue of every 
%     pixel in the image from the XYZ values of the multispectral image 
%     provided as the input. We compare the XYZImage values to the XYZ of 
%     standard daylight as a reference to obtain the imageHue.
%
% Input:
%   XYZImage = ImageSz x ImageSz x 3 matrix of XYZ values
%
% Output:
%   imageColor = ImageSz x ImageSz x 3 matrix of HSL values
%
% 11/03/2016    VS wrote it
%
imageColor = zeros(size(XYZImage,1),size(XYZImage,2),3);
theWavelengths = [400:5:700]';
%% Load in spectral weighting function for luminance
% This is the 1931 CIE standard
theXYZData = load('T_xyz1931');
theXYZCMFs = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);

%% Load in a standard daylight as our reference spectrum
theIlluminantData = load('spd_D65');
theIlluminant = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
XYZD65 = theXYZCMFs*theIlluminant;

%% Convert XYZ to CIELAB hue
for ii = 1 : size(XYZImage,1)
    for jj = 1 : size(XYZImage,2)
        theLab = XYZToLab(squeeze(XYZImage(ii,jj,:)),XYZD65/XYZD65(2)*squeeze(XYZImage(ii,jj,2)));
        theLch = SensorToCyl(theLab);
        imageColor(ii,jj,:)= theLch;
    end
end

