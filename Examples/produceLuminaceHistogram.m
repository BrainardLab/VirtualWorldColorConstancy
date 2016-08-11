% produceLuminanceHistogram
%
% Generate a random refelctance using linear Gaussian model on
% sur_nickerson and sur_vrhel data set. Find the luminace this reflectance
% with respect to D65 illuminant and human soectral sensitivity. Plot a
% histogram of the resulting luminances.

% 8/4/16  vs, vs  Wrote it.

%% Clear
clear; close all;

% Desired wl sampling
S = [400 5 61];
theWavelengths = SToWls(S);
%% Munsell surfaces
load sur_nickerson
sur_nickerson = SplineSrf(S_nickerson,sur_nickerson,S);

%% Vhrel surfaces
load sur_vrhel 
sur_vrhel = SplineSrf(S_vrhel,sur_vrhel,S);

%% Put them together
sur_all = [sur_nickerson sur_vrhel];

%% Analyze with respect to a linear model
B = FindLinMod(sur_all,6);
sur_all_wgts = B\sur_all;
mean_wgts = mean(sur_all_wgts,2);
cov_wgts = cov(sur_all_wgts');

%% Generate some new surfaces
nNewSurfaces = 10000;
newSurfaces = zeros(S(3),nNewSurfaces);
newIndex = 1;
for i = 1:nNewSurfaces
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        ran_sur = B*ran_wgts;
        if (all(ran_sur >= 0) & all(ran_sur <= 1))
            newSurfaces(:,newIndex) = ran_sur;
            newIndex = newIndex+1;
            OK = true;
        end
    end
end


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
for ii = 1 : nNewSurfaces
    theReflectance = newSurfaces(:,ii);
    theLightToEye = theIlluminant.*theReflectance;
    theLuminance(ii) = theLuminanceSensitivity*theLightToEye;
    % fprintf('Got luminance of %g (arb. units)\n',theLuminance);
end

%%
figure; clf;
H=histogram(theLuminance,(0.01:0.01:1),'Normalization','pdf');
xlabel('Luminance (L)'); ylabel('P(L)');
title('PDF of luminance for 10000 randomly generated reflectances');

figure; clf;
histogram(theLuminance,(0.01:0.01:1),'Normalization','cumcount');
xlabel('Luminance (L)'); ylabel('C(L)');
title('CDF of 10000 randomly generated reflectances');
