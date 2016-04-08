% ComputeHueExample
%
% Show how to compute the hue associated with a surface reflectance
% function, and then scale the reflectance to have a desired luminance.

% 4/8/16  dhb, vs, jdb  Wrote it.

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
theXYZCMFs = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);
figure; clf; hold on
plot(theWavelengths,theXYZCMFs');
xlabel('Wavelength'); ylabel('XYZ Tristimulus Value');
title('CIE 1931 XYZ Color Matching Functions');

%% Load in a standard daylight as our reference spectrum
%
% We'll scale this so that it has a luminance of 1, to help us think
% clearly about the scale of reference luminances we are interested in
% studying.
theIlluminantData = load('spd_D65');
theIlluminant = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
figure; clf; hold on
plot(theWavelengths,theIlluminant,'r');
xlabel('Wavelength'); ylabel('Relative Illuminant Power');
title('CIE Illuminant D65');

%% Compute XYZ coordinates of the light relfected to the eye
% First compute light reflected to the eye from the surface,
% then XYZ.
theLightToEye = theIlluminant.*theReflectance;
theXYZ = theXYZCMFs*theLightToEye;
theIlluminantXYZ = theXYZCMFs*theIlluminant;

%% Convert XYZ to CIELAB hue
theLab = XYZToLab(theXYZCMFs,theIlluminantXYZ);
theLch = SensorToCyl(theLab);
hueAngle = theLch(3);
fprintf('The hue angle is %0.1f radians\n',hueAngle);

