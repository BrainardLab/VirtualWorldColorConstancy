function trueColor = calculateTrueColor(targetLuminanceLevel, reflectanceNumber, recipeConds)

% This function calcualtes the hue of the target material given the
% luminance level and the reflectance number. The corresponding file is
% read from the VirtualWorldColorConstancy/Resources/Reflectance folder and
% the hue under standard D65 illumination is returned.
%
% trueHue = calculateTrueHue(0.4, 501);
%
% 11/03/2016    VS wrote it


%% Load in the reflectance function for the given recipe conditions
reflectanceFileName = sprintf('luminance-%.4f-reflectance-%03d.spd', ...
                targetLuminanceLevel, reflectanceNumber);
pathtoReflectanceFile = fullfile(recipeConds.Working.fullPath,'resources',reflectanceFileName);
[theWavelengths, theReflectance] = rtbReadSpectrum(pathtoReflectanceFile);
            
% figure; clf; hold on
% plot(theWavelengths,theReflectance,'r');
% ylim([0 1]);
% xlabel('Wavelength'); ylabel('Matte Reflectance');
% title('The Reflectance Function');

%% Load in spectral weighting function for luminance
% This is the 1931 CIE standard
theXYZData = load('T_xyz1931');
theXYZCMFs = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);

% figure; clf; hold on
% plot(theWavelengths,theXYZCMFs');
% xlabel('Wavelength'); ylabel('XYZ Tristimulus Value');
% title('CIE 1931 XYZ Color Matching Functions');

%% Load in a standard daylight as our reference spectrum

theIlluminantData = load('spd_D65');
theIlluminant = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);

% figure; clf; hold on
% plot(theWavelengths,theIlluminant,'r');
% xlabel('Wavelength'); ylabel('Relative Illuminant Power');
% title('CIE Illuminant D65');

%% Compute XYZ coordinates of the light relfected to the eye
% First compute light reflected to the eye from the surface,
% then XYZ.
theLightToEye = theIlluminant.*theReflectance;
XYZSur = theXYZCMFs*theLightToEye;
XYZD65 = theXYZCMFs*theIlluminant;

%% Convert XYZ to CIELAB hue
theLab = XYZToLab(XYZSur,XYZD65);
trueColor = SensorToCyl(theLab);
% fprintf('The hue angle is %0.1f radians\n',trueHue);

