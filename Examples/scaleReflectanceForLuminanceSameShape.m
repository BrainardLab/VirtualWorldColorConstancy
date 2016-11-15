% scaleReflectanceForLuminanceSameShape
%
% This function is similar to scaleReflectanceForLuminance. 
% Here, reflectances are generated such that the shape is the same for all
% luminance values. We generate the reflectance for the largest luminance 
% value first and then rescale the reflectance values for the other 
% luminance levels. This automatically takes care of energy conservation
% and reflectance < 1 and >0, etc.
%
% 10/21/16  vs, VS  Wrote it.

%% Clear
clear; close all;

nLuminanceLevels=10;
luminanceLevelStart = 0.2;
luminanceLevelEnd = 0.6;
nSurfaceAtEachLuminance = 10;
% luminanceLevels = logspace(log10(0.2),log10(0.6),nLuminanceLevels);
luminanceLevels = [luminanceLevelStart:(luminanceLevelEnd-luminanceLevelStart)/(nLuminanceLevels-1):luminanceLevelEnd];

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

%% Generate a surface at largest luminance

OK = false;
while (~OK)
    ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
    theReflectance = B*ran_wgts+sur_mean;
    theLightToEye = theIlluminant.*theReflectance;
    theLuminance = theLuminanceSensitivity*theLightToEye;
    theLuminanceTarget = luminanceLevels(end);
    scaleFactor = theLuminanceTarget / theLuminance;
    theReflectanceScaled = scaleFactor * theReflectance;
    if (all(theReflectanceScaled >= 0) & all(theReflectanceScaled <= 1))
        reflectanceAtLargestLuminance = theReflectanceScaled;
        OK = true;
    end
end
%%
newSurfaces = zeros(S(3),size(luminanceLevels,2)*nSurfaceAtEachLuminance);
newIndex = 1;
for i = 1:(size(luminanceLevels,2)*nSurfaceAtEachLuminance)
    OK = false;
    while (~OK)

        theLightToEye = theIlluminant.*reflectanceAtLargestLuminance;
        theLuminance = theLuminanceSensitivity*theLightToEye;
        theLuminanceTarget = luminanceLevels(ceil(i/nSurfaceAtEachLuminance));
        scaleFactor = theLuminanceTarget / theLuminance;
        theReflectanceScaled = scaleFactor * theReflectance;
        if (all(theReflectanceScaled >= 0) & all(theReflectanceScaled <= 1))
            newSurfaces(:,newIndex) = theReflectanceScaled;
            newIndex = newIndex+1;
            OK = true;
        end
    end
    reflectanceName = sprintf('luminance-%.4f-reflectance-%03d.spd', theLuminanceTarget, ...
                rem(i,nSurfaceAtEachLuminance)+501);
    fid = fopen(reflectanceName ,'w');
    fprintf(fid,'%3d %3.6f\n',[theWavelengths,theReflectanceScaled]');
    fclose(fid);

end
%%
% figure; clf;
% for i = 1:nLuminanceLevels
%     plot(SToWls(S),newSurfaces(:,(i-1)*nSurfaceAtEachLuminance+1:i*nSurfaceAtEachLuminance));
%     title(['Luminance Level is = ',num2str(luminanceLevels(i))]);
%     print(gcf,['ReflectanceSpectra_LuminanceLevel',num2str(i)],'-dpng');
% end
 