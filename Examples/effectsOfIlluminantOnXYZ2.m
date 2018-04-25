function effectsOfIlluminantOnXYZ2
% This function produces some random illuminants at a few values of XYZ
% under D65. Then it genreates some random illuminants. Then assuming that
% the average reflectance over all surfaces in the world is known, it
% calcuates the XYZ under any arbitrary light. The results are plotted in
% the figures.
% The first subplot (top left) gives the XYZ under D65.
% The second subplot (top right) gives the XYZ under fixed random illuminant.
% The third subplot (bottom left) gives the XYZ under random illuminant.
% The fourth subplot (bottom right) gives the XYZ under fixed random
% illuminant, evalued assuming a contrast definition.
%
% Vijay Singh
% April 19, 2018

colors={'-*r', '-*b', '-*g', '-*k', '-*m', '-*c', '-*k', '-*g', '-*b'};
% Choose some luminance levels
% XYZLevels = [0.3 0.3 0.3; 0.4 0.4 0.4; 0.5 0.5 0.5; 0.6 0.6 0.6]';
XYZLevels = [1 1 1]'*[0.1:0.1:0.7];
reflectanceNumbers = [1:100];
nSamples = size(XYZLevels,2)*length(reflectanceNumbers);
% Desired wl sampling
S = [400 5 61];
theWavelengths = SToWls(S);

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
D65 = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
D65 = D65/(theLuminanceSensitivity(2,:)*D65);


%% Generate some reflectances at the target luminance levels
targetReflectances = getReflectances(XYZLevels, reflectanceNumbers, theWavelengths, S);

% Check by plotting that the luminance levels were properly assigned
actualXYZ = theLuminanceSensitivity*diag(D65)*targetReflectances;

Fig1=figure;
set(Fig1,'units','pixels', 'Position', [1, 1000, 800, 880]);
subplot(2,2,1);
hold on;
title('XYZ under D65');
box on;
for ii = 1:size(XYZLevels,2)
    thisLevelIndices = (ii-1)*length(reflectanceNumbers)+1:ii*length(reflectanceNumbers);
    plot3(actualXYZ(1,thisLevelIndices),actualXYZ(2,thisLevelIndices),actualXYZ(3,thisLevelIndices),colors{ii});
end
xlabel('X');
ylabel('Y');
zlabel('Z');
xlim([0 1]);
ylim([0 1]);
zlim([0 1]);
set(gca,'FontSize',15);
view(120, 30);
drawnow;

%% Generate a random illuminant spectrum
scaleFactor = 1; % 0 = Don't scale the mean value of the new spectra
                 % 1 = Scale the mean value of the new spectra to match
                 % with Granada

nIlluminant = nSamples; % Generate nIlluminant spectrum
newIlluminance = generateRandomIlluminant(S, scaleFactor, nIlluminant);

%% Get the value of luminance under fixed random spectrum
fixedIlluminant = newIlluminance(:,randi(nSamples));

XYZFixedIlluminant = theLuminanceSensitivity*diag(fixedIlluminant)*targetReflectances;

% Plot these luminances
subplot(2,2,2);
hold on;
title('XYZ random illuminant');
box on;
for ii = 1:size(XYZLevels,2)
    thisLevelIndices = (ii-1)*length(reflectanceNumbers)+1:ii*length(reflectanceNumbers);
    plot3(XYZFixedIlluminant(1,thisLevelIndices),XYZFixedIlluminant(2,thisLevelIndices),...
        XYZFixedIlluminant(3,thisLevelIndices),colors{ii});
end
xlabel('X');
ylabel('Y');
zlabel('Z');
set(gca,'FontSize',15);
view(120, 30);
drawnow;

%% Get the value of luminance under random spectrum
% Each reflectance spectrum is evaluated under a different random
% illuminant
for ii = 1:nSamples
    XYZRandomIlluminant(:,ii) = theLuminanceSensitivity*diag(newIlluminance(:,ii))*targetReflectances(:,ii);
end

% Plot these luminances
subplot(2,2,3);
hold on;
title('Random illuminant (Isomerization)');
box on;
for ii = 1:size(XYZLevels,2)
    thisLevelIndices = (ii-1)*length(reflectanceNumbers)+1:ii*length(reflectanceNumbers);
    plot3(XYZRandomIlluminant(1,thisLevelIndices),XYZRandomIlluminant(2,thisLevelIndices),...
        XYZRandomIlluminant(3,thisLevelIndices),colors{ii});
end
plot3(XYZRandomIlluminant(1,:),XYZRandomIlluminant(2,:),XYZRandomIlluminant(3,:),'.');
xlabel('X');
ylabel('Y');
zlabel('Z');
set(gca,'FontSize',15);
view(120, 30);
drawnow;

%% Get the value of luminance under random spectrum through contrast calculation
% Each reflectance spectrum is evaluated under a different random
% illuminant
% for ii = 1:nSamples
%     XYZRandomIlluminantContrast(:,ii) = returnLuminanceThroughContrast(S, ...
%         targetReflectances(:,ii), newIlluminance(:,ii), theLuminanceSensitivity);
% end

% This is the model of the mean reflectance
for ii = 1: nSamples
    meanReflectance(:,ii) = getObjectReflectances(10, S);
end

XYZOfMeanReflectance =zeros(3,nSamples);
XYZRandomIlluminantContrast =zeros(3,nSamples);

for ii = 1:nSamples
    XYZOfMeanReflectance(:,ii) = theLuminanceSensitivity*diag(newIlluminance(:,ii))*meanReflectance(:,ii);
    XYZRandomIlluminantContrast(:,ii) = theLuminanceSensitivity*diag(newIlluminance(:,ii))*targetReflectances(:,ii);
end
XYZRandomIlluminantContrast = 1./(1+XYZOfMeanReflectance./XYZRandomIlluminantContrast);

% Plot these luminances
subplot(2,2,4);
hold on;
title('Random illuminant (Contrast)');
box on;
for ii = 1:size(XYZLevels,2)
    thisLevelIndices = (ii-1)*length(reflectanceNumbers)+1:ii*length(reflectanceNumbers);
    plot3(XYZRandomIlluminantContrast(1,thisLevelIndices),XYZRandomIlluminantContrast(2,thisLevelIndices),...
        XYZRandomIlluminantContrast(3,thisLevelIndices),colors{ii});
end
plot3(XYZRandomIlluminantContrast(1,:),XYZRandomIlluminantContrast(2,:),XYZRandomIlluminantContrast(3,:),'.');
xlabel('X');
ylabel('Y');
zlabel('Z');
set(gca,'FontSize',15);
view(120, 30);
drawnow;

end

function targetReflectances = getReflectances(XYZValues, reflectanceNumbers, theWavelengths, S)
% This function makes the target reflectances at the desired luminance levels

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
newSurfaces = zeros(S(3),size(XYZValues,2)*nsurfacePerXYZ);
newIndex =0;

for ii = 1:size(XYZValues,2)
    m=0;
    ww(:,ii) = (theLuminanceSensitivity*diag(theIlluminant)*B)\...
        (XYZValues(:,ii) - theLuminanceSensitivity*diag(theIlluminant)*sur_mean);

    %Generate nReflectance surfaces for this random weight set
while (m < nsurfacePerXYZ)
    m=m+1;
    OK = false;
    while (~OK)
        newWeights = ww(:,ii) + nullSpace*(0.95*norm(ww(:,ii)))*rand(3,1);
        newReflectance = B*newWeights+sur_mean;
        if (all(newReflectance(:) >= 0) & all(newReflectance(:) <= 1))
            newIndex = newIndex+1;
            newSurfaces(:,newIndex) = newReflectance;
            OK = true;
        end
    end
end
end
targetReflectances = newSurfaces;
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

% objectReflectances = B*mean_wgts+sur_mean;
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
objectReflectances = mean(newSurfaces,2);
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

mm = minmax(meanDaylightGranada);
scales = 10.^(log10(mm(1)) + (log10(mm(2))-log10(mm(1))) * rand(1,nNewIlluminaces));

for i = 1:nNewIlluminaces
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        ran_ill = B*ran_wgts+meandaylightGranadaRescaled;
        if (all(ran_ill >= 0))
            newIlluminance(:,newIndex) = ran_ill;
            if (scaleFactor ~= 0)
                newIlluminance(:,newIndex) = newIlluminance(:,newIndex)*...
                    (meanDaylightGranada(randi(length(meanDaylightGranada))))*scales(i);
            end
            newIndex = newIndex+1;
            OK = true;
        end
    end
end

end
