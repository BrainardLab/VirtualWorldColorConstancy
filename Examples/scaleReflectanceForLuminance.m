% scaleReflectanceForLuminance
%
% Generate reflectances at particluar luminances, making sure that the
% reflectance at every wavelength is lower than 1.
%
% 8/10/16  vs, vs  Wrote it.

%% Clear
clear; close all;

luminanceLevels = log10(logspace(log10(10^(0.2)),log10(10^(0.6)),20));
nSurfaceAtEachLuminace = 100;

% Desired wl sampling
S = [400 5 61];
theWavelengths = SToWls(S);
%% Load Natural Surfaces

% Munsell surfaces
load sur_nickerson
sur_nickerson = SplineSrf(S_nickerson,sur_nickerson,S);

% Vhrel surfaces
load sur_vrhel 
sur_vrhel = SplineSrf(S_vrhel,sur_vrhel,S);

% Put them together
sur_all = [sur_nickerson sur_vrhel];

%% Analyze with respect to a linear model
B = FindLinMod(sur_all,6);
sur_all_wgts = B\sur_all;
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
for i = 1:(size(luminanceLevels,2)*nSurfaceAtEachLuminace)
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        theReflectance = B*ran_wgts;
        theLightToEye = theIlluminant.*theReflectance;
        theLuminance = theLuminanceSensitivity*theLightToEye;
        theLuminanceTarget = luminanceLevels(ceil(i/nSurfaceAtEachLuminace));
        scaleFactor = theLuminanceTarget / theLuminance;
        theReflectanceScaled = scaleFactor * theReflectance;
        if (all(theReflectanceScaled >= 0) & all(theReflectanceScaled <= 1))
            newSurfaces(:,newIndex) = theReflectanceScaled;
            newIndex = newIndex+1;
            OK = true;
        end
    end
    reflectanceName = sprintf('luminance-%.4f-reflectance-%03d.spd', theLuminanceTarget, ...
                rem(i,nSurfaceAtEachLuminace)+1);
    fid = fopen(reflectanceName ,'w');
    fprintf(fid,'%3d %3.6f\n',[theWavelengths,theReflectanceScaled]');
    fclose(fid);

end
