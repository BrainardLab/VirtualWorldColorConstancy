% ComputeLuminanceExample
%
% Show how to compute the luminance associated with a surface reflectance
% function, and then scale the reflectance to have a desired luminance.

% 3/11/16  dhb, vs  Wrote it.

%% Clear
clear; close all;

%% Load in some surface reflectance functions
whichMaterial = 3;
matteMacbethMaterials = GetWardLandMaterials;
theMaterial = matteMacbethMaterials{whichMaterial};
theReflectanceData = load(theMaterial.properties.propertyValue);
theWavelengths = theReflectanceData(:,1);
theReflectance = theReflectanceData(:,2);
figure; clf; hold on
plot(theWavelengths,theReflectance,'r');
ylim([0 1]);
xlabel('Wavelength'); ylabel('Matte Reflectance');
title('The Reflectance Function');

%% Load in spectral weighting function for luminance
% This is the 1931 CIE standard
theXYZData = load('T_xyz1931');
theLuminanceSensitivity = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931(2,:),theWavelengths);
figure; clf; hold on
plot(theWavelengths,theLuminanceSensitivity,'r');
ylim([0 1]);
xlabel('Wavelength'); ylabel('Luminance Sensitivity');
title('Spectral Luminance Function');

%% Load in a standard daylight as our reference spectrum
%
% We'll scale this so that it has a luminance of 1, to help us think
% clearly about the scale of reference luminances we are interested in
% studying.
theIlluminantData = load('spd_D65');
theIlluminant = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
theIlluminant = theIlluminant/(theLuminanceSensitivity*theIlluminant);
figure; clf; hold on
plot(theWavelengths,theIlluminant,'r');
xlabel('Wavelength'); ylabel('Relative Illuminant Power');
title('D65');

%% Compute luminance of our surface under the illuminant
% First compute light reflected to the eye from the surface,
% then compute luminance.
theLightToEye = theIlluminant.*theReflectance;
theLuminance = theLuminanceSensitivity*theLightToEye;
fprintf('Got luminance of %g (arb. units)\n',theLuminance);

%% Sometimes we want to scale the reflectance to give us a target luminance
%
% Just as a check of our scaling of the illuminant and luminance units,
% make sure that uniform reflectors produce expected luminance in a direct
% forward calculation.
lowReflectance = 0.03;
highReflectance = 0.90;
luminanceLow = theLuminanceSensitivity*(theIlluminant*lowReflectance);
luminanceHigh = theLuminanceSensitivity*(theIlluminant*highReflectance);
fprintf('Reasonable luminances in our arbitrary units: low = %g, high = %g\n',luminanceLow,luminanceHigh);

% Scale the reflectance
theLuminanceTarget = 0.4;
theReflectanceScaled = theLuminanceTarget*theReflectance/theLuminance;
theLuminanceScaled = theLuminanceSensitivity*(theIlluminant.*theReflectanceScaled);
fprintf('Target luminance = %g, actual scaled luminance = %g\n',theLuminanceTarget,theLuminanceScaled);

