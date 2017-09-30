function makeTargetReflectanceScaledCopies(luminanceLevels,reflectanceNumbers, folderToStore)
% makeTargetReflectanceScaledCopies(luminanceLevels,reflectanceNumbers, folderToStore)
%
% Usage: 
%     makeTargetReflectanceScaledCopies([0.2 0.4 0.6] ,[1:5], 'ExampleFolderName')
%
% Description:
%     This function generates target object reflectances that have the same
%     shape at each reflectance number. It generates one set of target
%     object reflectance spectra at the luminance level and scales it such
%     that at the other luminance level the shape is the same. We have
%     ensured that the same shape reflectnaces are numbered by their
%     reflectance numbers.
%
%    The spectrum are generated using the nickerson and the 
%    vrhel libraries. These libraries should be a part of
%    RenderToolbox. To generate the spectra, we first find out the pricipal
%    components of the spectra in the library. Then we choose the
%    directions corresponding to the largest six eigenvalues. We project
%    the spectra along these six directions and find out the mean and the
%    variance of this distribution. These are then used along with a
%    multinormal random distribution to generate new random spectra. The
%    new spectra are scaled such that the luminance equals the desired
%    luminance levels. Finally, we make sure that the reflectance spectra 
%    values are between 0 and 1 at all frequencies.
%
% Input:
%   luminanceLevels = luminance levels for which the spectra are generated
%   reflectanceNumbers = reflectance numbers for naming the files
%   folderToStore = folder where the new spectra should be stored
%
%
% 09/30/2017 vs  wrote it.

% Desired wl sampling
S = [400 5 61];
theWavelengths = SToWls(S);

nSurfaceAtEachLuminance = numel(reflectanceNumbers);
%% Load surfaces
%
% These are in the Psychtoolbox.

% Munsell surfaces
load sur_nickerson
sur_nickerson = SplineSrf(S_nickerson,sur_nickerson,S);

% Vhrel surfaces
load sur_vrhel
sur_vrhel = SplineSrf(S_vrhel,sur_vrhel,S);

% Put them together
sur_all = [sur_nickerson sur_vrhel];

sur_mean=mean(sur_all,2);
sur_all_mean_centered = bsxfun(@minus,sur_all,sur_mean);

%% Analyze with respect to a linear model
B = FindLinMod(sur_all_mean_centered,6);
sur_all_wgts = B\sur_all_mean_centered;
mean_wgts = mean(sur_all_wgts,2);
cov_wgts = cov(sur_all_wgts');

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

%% Generate new surfaces
newSurfaces = zeros(S(3),size(luminanceLevels,2)*nSurfaceAtEachLuminance);
newIndex = 1;

if ~exist(folderToStore)
    mkdir(folderToStore);
end

for i = 1:nSurfaceAtEachLuminance
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        theReflectance = B*ran_wgts+sur_mean;
        theLightToEye = theIlluminant.*theReflectance;
        theLuminance = theLuminanceSensitivity*theLightToEye;
        
        % Make the reflectances
        for jj = 1:length(luminanceLevels)
            theLuminanceTarget = luminanceLevels(jj);
            scaleFactor = theLuminanceTarget / theLuminance;
            theReflectanceScaled = scaleFactor * theReflectance;
            if (all(theReflectanceScaled >= 0) & all(theReflectanceScaled <= 1))
                newSurfaces(:,newIndex) = theReflectanceScaled;
                newIndex = newIndex+1;
                OK = true;
            end
            reflectanceName = sprintf('luminance-%.4f-reflectance-%03d.spd',...
                theLuminanceTarget, reflectanceNumbers(i));
            fid = fopen(fullfile(folderToStore,reflectanceName),'w');
            fprintf(fid,'%3d %3.6f\n',[theWavelengths,theReflectanceScaled]');
            fclose(fid);
        end
    end    
end