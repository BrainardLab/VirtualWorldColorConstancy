function makeFlatTargetReflectance(luminanceLevels,reflectanceNumbers, folderToStore)
% makeTargetReflectance(luminanceLevels,nSurfaceAtEachLuminace, folderToStore)
%
% Generate reflectances at particluar luminance levels. The spectrum is
% spectrally flat for each luminance level.
%
% 02/02/2017 VS  Wrote it.

% Desired wl sampling
if ~exist(folderToStore)
    mkdir(folderToStore);
end

S = [400 5 61];
theWavelengths = SToWls(S);

nSurfaceAtEachLuminace = numel(reflectanceNumbers);
theLuminanceTarget=reshape(repmat([0.2:0.4/9:0.6],10,1),100,1)';

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
m=0;
for i = 1:(size(luminanceLevels,2)*nSurfaceAtEachLuminace)
    m=m+1;    
    OK = false;
    while (~OK)
        theReflectance = ones(numel(theWavelengths),1);
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
                reflectanceNumbers(m));
    fid = fopen(fullfile(folderToStore,reflectanceName),'w');
    fprintf(fid,'%3d %3.6f\n',[theWavelengths,theReflectanceScaled]');
    fclose(fid);
    if (m==numel(reflectanceNumbers)) m=0; end
end