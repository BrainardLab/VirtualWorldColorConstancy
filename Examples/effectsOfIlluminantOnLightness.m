function actualLuminance = effectsOfIlluminantOnLightness
% This script makes random reflectance spectra at specified luminance
% levels. The luminance levels are assigned as if the object with this
% reflectnace spectrum was observed by an average human observer under
% standard daylight CIE D65.
%
% Vijay Singh
% April 10, 2018

colors={'r', 'b', 'g', 'k', 'm', 'c', 'k', 'g', 'b'};
% Choose some luminance levels
luminanceLevels = linspace(0.2, 0.6,9);
reflectanceNumbers = [1:100];
nSamples = length(luminanceLevels)*length(reflectanceNumbers);
% Desired wl sampling
S = [400 5 61];
theWavelengths = SToWls(S);

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
D65 = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
D65 = D65/(theLuminanceSensitivity*D65);

%% Generate some reflectances at the target luminance levels
targetReflectances = getReflectances(luminanceLevels, reflectanceNumbers, theWavelengths, S);

targetReflectancesReshaped = reshape(targetReflectances, ...
    [], length(luminanceLevels)*length(reflectanceNumbers));

% Check by plotting that the luminance levels were properly assigned
for ii = 1:nSamples
    actualLuminance(ii) = ...
        returnLuminanceFromSpectra(targetReflectancesReshaped(:,ii), D65, theLuminanceSensitivity);
end

Fig1=figure;
set(Fig1,'units','pixels', 'Position', [1, 1000, 800, 880]);
subplot(2,2,1);
hold on;
title('Luminance under D65');
box on;
for jj = 1:length(luminanceLevels)
    plot([(jj-1)*length(reflectanceNumbers)+1:jj*length(reflectanceNumbers)], ...
        actualLuminance((jj-1)*length(reflectanceNumbers)+1:jj*length(reflectanceNumbers)), colors{jj});
end
xlabel('Rflectance Index');
ylabel('Actual Luminance');
ylim([0.15 0.65]);
axis square;
set(gca,'FontSize',15)

%% Generate a random illuminant spectrum
scaleFactor = 1; % 0 = Don't scale the mean value of the new spectra
                 % 1 = Scale the mean value of the new spectra to match
                 % with Granada

nIlluminant = nSamples; % Generate nIlluminant spectrum
newIlluminance = generateRandomIlluminant(S, scaleFactor, nIlluminant);

%% Get the value of luminance under fixed random spectrum
fixedIlluminant = newIlluminance(randi(nSamples));
for ii = 1:nSamples
    newLuminanceFixedIlluminant(ii) = returnLuminanceFromSpectra(targetReflectancesReshaped(:,ii), ...
                fixedIlluminant, theLuminanceSensitivity);
end
newLuminanceFixedIlluminant = reshape(newLuminanceFixedIlluminant, ...
                    length(reflectanceNumbers), length(luminanceLevels));
meanLuminanceFixedIlluminant = mean(newLuminanceFixedIlluminant);
stdLuminanceFixedIlluminant = std(newLuminanceFixedIlluminant);

% Plot these luminances
subplot(2,2,2);
hold on;
title('Fixed Random Illuminant');
box on;
for jj = 1:length(luminanceLevels)
    tempMean = meanLuminanceFixedIlluminant(jj);
    tempStd = stdLuminanceFixedIlluminant(jj);
    
    xx = linspace(tempMean-3*tempStd,tempMean+3*tempStd,100);
    yy = exp(-(xx-tempMean).^2/2/(tempStd.^2))/(sqrt(2*pi*tempStd));
    
    plot(xx, yy, colors{jj});
end
xlabel('L');
ylabel('P(L)');
% ylim([0.15 0.65]);
axis square;
set(gca,'FontSize',15)

%% Get the value of luminance under random spectrum
% Each reflectance spectrum is evaluated under a different random
% illuminant
for ii = 1:nSamples
    newLuminanceRandomIlluminant(ii) = returnLuminanceFromSpectra(targetReflectancesReshaped(:,ii), ...
                        newIlluminance(ii), theLuminanceSensitivity);
end

newLuminanceRandomIlluminant = reshape(newLuminanceRandomIlluminant, ...
                    length(reflectanceNumbers), length(luminanceLevels));
meanLuminanceRandomIlluminant = mean(newLuminanceRandomIlluminant);
stdLuminanceRandomIlluminant = std(newLuminanceRandomIlluminant);

% Plot these luminances
subplot(2,2,3);
hold on;
title('Random Illuminant (Isomerization)');
box on;
for jj = 1:length(luminanceLevels)
    tempMean = meanLuminanceRandomIlluminant(jj);
    tempStd = stdLuminanceRandomIlluminant(jj);
    
    xx = linspace(tempMean-3*tempStd,tempMean+3*tempStd,100);
    yy = exp(-(xx-tempMean).^2/2/(tempStd.^2))/(sqrt(2*pi*tempStd));
    
    plot(xx, yy, colors{jj});
end
xlabel('L');
ylabel('P(L)');
% ylim([0.15 0.65]);
axis square;
set(gca,'FontSize',15)

%% Get the value of luminance under random spectrum through contrast calculation
% Each reflectance spectrum is evaluated under a different random
% illuminant
for ii = 1:nSamples
    newLuminanceRandomIlluminantContrast(ii) = returnLuminanceThroughContrast(S, ...
        targetReflectancesReshaped(:,ii), newIlluminance(ii), theLuminanceSensitivity);
end

newLuminanceRandomIlluminantContrast = reshape(newLuminanceRandomIlluminantContrast, ...
                    length(reflectanceNumbers), length(luminanceLevels));
meanLuminanceFixedIlluminantContrast = mean(newLuminanceRandomIlluminantContrast);
stdLuminanceFixedIlluminantContrast = std(newLuminanceRandomIlluminantContrast);

% Plot these luminances
subplot(2,2,4);
hold on;
title('Random Illuminant (Contrast)');
box on;
for jj = 1:length(luminanceLevels)
    tempMean = meanLuminanceFixedIlluminantContrast(jj);
    tempStd = stdLuminanceFixedIlluminantContrast(jj);
    
    xx = linspace(tempMean-3*tempStd,tempMean+3*tempStd,100);
    yy = exp(-(xx-tempMean).^2/2/(tempStd.^2))/(sqrt(2*pi*tempStd));
    
    plot(xx, yy, colors{jj});
end
xlabel('L');
ylabel('P(L)');
axis square;
set(gca,'FontSize',15)

end

function targetReflectances = getReflectances(luminanceLevels,reflectanceNumbers, theWavelengths, S)
% This function makes the target reflectances at the desired luminance levels

nSurfaceAtEachLuminace = numel(reflectanceNumbers);

%% Load surfaces
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

m=0;
for i = 1:(size(luminanceLevels,2)*nSurfaceAtEachLuminace)
    m=m+1;
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        theReflectance = B*ran_wgts+sur_mean;
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
    if (m==numel(reflectanceNumbers)) m=0; end
end
targetReflectances = reshape(newSurfaces,S(3),size(luminanceLevels,2),nSurfaceAtEachLuminace);
end

function objectReflectances = getObjectReflectances(nSurfaces, S)

%% Load surfaces
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

%% Generate new surfaces
newSurfaces = zeros(S(3),nSurfaces);
newIndex = 1;

for i = 1:nSurfaces
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        ran_sur = B*ran_wgts+sur_mean;
        if (all(ran_sur >= 0) & all(ran_sur <= 1))
            newSurfaces(:,newIndex) = ran_sur;
            newIndex = newIndex+1;
            OK = true;
        end
    end
end    
objectReflectances = newSurfaces;
end

function newIlluminance = generateRandomIlluminant(S, scaleFactor, nIlluminances)

%% Load Granada Illumimace data
pathToIlluminanceData = fullfile(fileparts(fileparts(mfilename('fullpath'))),'Data/IlluminantSpectra');
load(fullfile(pathToIlluminanceData,'daylightGranadaLong'));
daylightGranadaOriginal = SplineSrf(S_granada,daylightGranada,S);

% Rescale spectrum by its mean
meanDaylightGranada = mean(daylightGranadaOriginal);
daylightGranadaRescaled = bsxfun(@rdivide,daylightGranadaOriginal,meanDaylightGranada);

meandaylightGranadaRescaled = mean(daylightGranadaRescaled,2);
daylightGranadaRescaledMeanSubtracted = bsxfun(@minus,daylightGranadaRescaled,meandaylightGranadaRescaled);

%% Analyze with respect to a linear model
B = FindLinMod(daylightGranadaRescaledMeanSubtracted,6);
ill_granada_wgts = B\daylightGranadaRescaledMeanSubtracted;
mean_wgts = mean(ill_granada_wgts,2);
cov_wgts = cov(ill_granada_wgts');

%% Generate some new illuminants
nNewIlluminaces = nIlluminances;
newIlluminance = zeros(S(3),nNewIlluminaces);
newIndex = 1;

for i = 1:nNewIlluminaces
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        ran_ill = B*ran_wgts+meandaylightGranadaRescaled;
        if (all(ran_ill >= 0))
            newIlluminance(:,newIndex) = ran_ill;
            if (scaleFactor ~= 0)
                newIlluminance(:,newIndex) = newIlluminance(:,newIndex)*...
                    (meanDaylightGranada(randi(length(meanDaylightGranada))))* ...
                    meandaylightGranadaRescaled(randi(length(meandaylightGranadaRescaled)));
            end
            newIndex = newIndex+1;
            OK = true;
        end
    end
end

end
function luminance = returnLuminanceFromSpectra(theReflectance, theIlluminant, theLuminanceSensitivity)

theLightToEye = theIlluminant.*theReflectance;
luminance = theLuminanceSensitivity*theLightToEye;

end

function luminance = returnLuminanceThroughContrast(S, theReflectance, theIlluminant, theLuminanceSensitivity)

theLightToEye = theIlluminant.*theReflectance;
luminance = theLuminanceSensitivity*theLightToEye;

nSurfaces = 100;
objectReflectances = getObjectReflectances(nSurfaces, S);

% Get the average luminance over random surfaces under this light
for ii = 1:nSurfaces
    theLightToEyeTemp = theIlluminant.*objectReflectances(:,ii);
    luminanceOfRandomSurface(ii) = theLuminanceSensitivity*theLightToEyeTemp;
end
luminanceOfRandomSurface(nSurfaces+1) = luminance;
averageLuminance = mean(luminanceOfRandomSurface);
luminance = luminance/averageLuminance;
end