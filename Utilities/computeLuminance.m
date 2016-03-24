function [theWavelengths, theReflectance, theReflectanceScaled] = computeLuminance(whichMaterial,theLuminanceTarget)

% This function takes the material number and target luminanace level and 
% returns the scaled reflectance for the given material based on the target
% luminance. The scaled reflectance would provide the 

% Compute the luminance associated with a surface reflectance
% function, and then scale the reflectance to have a desired luminance.

% 3/23/16 vs  wrote it.

% Load in the surface reflectance functions associated with whichMaterial

matteMacbethMaterials = GetWardLandMaterials;
theMaterial = matteMacbethMaterials{whichMaterial};
theReflectanceData = load(theMaterial.properties.propertyValue);
theWavelengths = theReflectanceData(:,1);
theReflectance = theReflectanceData(:,2);

%% Load in spectral weighting function for luminance
% This is the 1931 CIE standard
theXYZData = load('T_xyz1931');
theLuminanceSensitivity = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931(2,:),theWavelengths);

%% Load in a standard daylight as our reference spectrum
%
% We'll scale this so that it has a luminance of 1, to help us think
% clearly about the scale of reference luminances we are interested in
% studying.
theIlluminantData = load('spd_D65');
theIlluminant = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
theIlluminant = theIlluminant/(theLuminanceSensitivity*theIlluminant);

%% Compute luminance of our surface under the illuminant
% First compute light reflected to the eye from the surface,
% then compute luminance.
theLightToEye = theIlluminant.*theReflectance;
theLuminance = theLuminanceSensitivity*theLightToEye;

%% Sometimes we want to scale the reflectance to give us a target luminance
theReflectanceScaled = theLuminanceTarget*theReflectance/theLuminance;

end

