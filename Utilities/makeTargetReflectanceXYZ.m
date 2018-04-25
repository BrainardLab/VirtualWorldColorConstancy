function makeTargetReflectanceXYZ(XYZLevels,reflectanceNumbers, folderToStore)
% makeTargetReflectanceXYZ(XYZLevels, reflectanceNumbers, folderToStore)
%
% Usage: 
%     makeTargetReflectance([0.1 0.1 0.1]', [1:5], 'ExampleFolderName')
%
% Description:
%    This function makes the reflectance spectra for the target objects of
%    virtual world. The spectrum are generated using the nickerson and the 
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
% 8/10/16  vs, vs  Wrote it.

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
theLuminanceSensitivity = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);

%% Load in a standard daylight as our reference spectrum
%
% We'll scale this so that it has a luminance of 1, to help us think
% clearly about the scale of reference luminances we are interested in
% studying.
theIlluminantData = load('spd_D65');
theIlluminant = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
theIlluminant = theIlluminant/(theLuminanceSensitivity(2,:)*theIlluminant);

%% Get the null space
nullSpace = null(theLuminanceSensitivity*diag(theIlluminant)*B);

%% Generate new surfaces
nsurfacePerXYZ = length(reflectanceNumbers);
newSurfaces = zeros(S(3),size(XYZLevels,2)*nsurfacePerXYZ);
newIndex =0;


if ~exist(folderToStore)
    mkdir(folderToStore);
end

for ii = 1:size(XYZLevels,2)
    m=0;
    ww(:,ii) = (theLuminanceSensitivity*diag(theIlluminant)*B)\...
        (XYZLevels(:,ii) - theLuminanceSensitivity*diag(theIlluminant)*sur_mean);

    %Generate nReflectance surfaces for this random weight set
while (m < nsurfacePerXYZ)
    m=m+1;
    OK = false;
    while (~OK)
        newWeights = ww(:,ii) + nullSpace*(0.95*norm(ww(:,ii)))*rand(3,1);
        newReflectance = B*newWeights+sur_mean;
        theLuminanceTarget = XYZLevels(2,ii);
        if (all(newReflectance(:) >= 0) & all(newReflectance(:) <= 1))
            newIndex = newIndex+1;
            newSurfaces(:,newIndex) = newReflectance;
            OK = true;
        end
    end
    reflectanceName = sprintf('luminance-%.4f-reflectance-%03d.spd', theLuminanceTarget, ...
                reflectanceNumbers(m));
    fid = fopen(fullfile(folderToStore,reflectanceName),'w');
    fprintf(fid,'%3d %3.6f\n',[theWavelengths,newReflectance]');
    fclose(fid);
end
    if (m==numel(reflectanceNumbers)) m=0; end
end

end
