function makeSameShapeTargetReflectance(luminanceLevels,reflectanceNumbers, folderToStore)
% makeSameShapeTargetReflectance(luminanceLevels,nSurfaceAtEachLuminace, folderToStore)
%
%
% Generate surface reflectance spectra of same shape at specified luminance
% levels, making sure that the reflectance at every wavelength is lower 
% than 1.
%
% 07/19/2017 vs  wrote it.

% Desired wl sampling
S = [400 5 61];
theWavelengths = SToWls(S);

nSurfaceAtEachLuminace = numel(reflectanceNumbers);
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
newSurfaces = zeros(S(3),size(luminanceLevels,2)*nSurfaceAtEachLuminace);
newIndex = 1;

if ~exist(folderToStore)
    mkdir(folderToStore);
end

OK = false;
while (~OK)
    ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
    theReflectance = B*ran_wgts+sur_mean;
    theLightToEye = theIlluminant.*theReflectance;
    theLuminance = theLuminanceSensitivity*theLightToEye;
    
    m=0;
    for i = 1:(size(luminanceLevels,2)*nSurfaceAtEachLuminace)
        m=m+1;
        theLuminanceTarget = luminanceLevels(ceil(i/nSurfaceAtEachLuminace));
        scaleFactor = theLuminanceTarget / theLuminance;
        theReflectanceScaled = scaleFactor * theReflectance;
        if (all(theReflectanceScaled >= 0) & all(theReflectanceScaled <= 1))
            newSurfaces(:,newIndex) = theReflectanceScaled;
            newIndex = newIndex+1;
            OK = true;
        end
        
        reflectanceName = sprintf('luminance-%.4f-reflectance-%03d.spd', theLuminanceTarget, ...
            reflectanceNumbers(m));
        fid = fopen(fullfile(folderToStore,reflectanceName),'w');
        fprintf(fid,'%3d %3.6f\n',[theWavelengths,theReflectanceScaled]');
        fclose(fid);
        if (m==numel(reflectanceNumbers)) m=0; end
    end
end