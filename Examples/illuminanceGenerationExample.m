% Illuminance Generation example

% Clear
clear; close all;

% Desired wl sampling
nIlluminances = 100;

S = [400 5 61];
theWavelengths = SToWls(S);
%% Load Granada Illumimace data
load daylightGranadaLong
daylightGranadaOriginal = SplineSrf(S_granada,daylightGranada,S);
% maxDaylightGranada = max(daylightGranadaOriginal);  
% daylightGranadaRescaled = daylightGranadaOriginal./repmat(maxDaylightGranada,[size(daylightGranadaOriginal,1),1]);
% meanDaylightGranada = mean(daylightGranadaOriginal);  
% daylightGranadaRescaled = daylightGranadaOriginal./repmat(meanDaylightGranada,[size(daylightGranadaOriginal,1),1]);

% From each spectra subtract its mean value
meanDaylightGranada = mean(daylightGranadaOriginal);  
daylightGranadaMeanCentered = bsxfun(@minus,daylightGranadaOriginal,meanDaylightGranada);

% Normalize the mean values by their L2 norm
lengthDaylightGranada = sqrt(sum(daylightGranadaMeanCentered.*daylightGranadaMeanCentered));  
daylightGranadaRescaled = daylightGranadaMeanCentered./repmat(lengthDaylightGranada,[size(daylightGranadaOriginal,1),1]);

% Add the mean value rescaled by the L2 norm
daylightGranadaRescaled = bsxfun(@plus,daylightGranadaRescaled,meanDaylightGranada./lengthDaylightGranada);

% Center the data for PCA
meandaylightGranadaRescaled = mean(daylightGranadaRescaled,2);
daylightGranadaRescaledMeanSubtracted = bsxfun(@minus,daylightGranadaRescaled,meandaylightGranadaRescaled);


%% Analyze with respect to a linear model
B = FindLinMod(daylightGranadaRescaledMeanSubtracted,6);
ill_granada_wgts = B\daylightGranadaRescaledMeanSubtracted;
mean_wgts = mean(ill_granada_wgts,2);
cov_wgts = cov(ill_granada_wgts');

%% Generate some new surfaces
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
            newIndex = newIndex+1;
            OK = true;
        end
    end
end

%% Load in the T_xyz1931 data for luminance sensitivity
theXYZData = load('T_xyz1931');
theLuminanceSensitivity = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);
theLuminanceSensitivityIll = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);

%% Compute XYZ
IlluminantXYZ = theLuminanceSensitivityIll*newIlluminance;
IlluminantxyY = XYZToxyY(IlluminantXYZ);
IlluminantXYZGranada = theLuminanceSensitivity*daylightGranadaRescaled;
IlluminantxyYGranada = XYZToxyY(IlluminantXYZGranada);

%% Convert to linear SRGB
SRGBPrimaryIll = XYZToSRGBPrimary(IlluminantXYZ);% Primary Illuminance 
SRGBPrimaryNormIll = SRGBPrimaryIll/max(SRGBPrimaryIll(:));
SRGBIll = SRGBGammaCorrect(SRGBPrimaryNormIll,false)/255;
    
%% Reshape the matrices for plotting as squares

for ii =1 :10
    for jj= 1:10
        theIlluminationImage(ii,jj,:)=SRGBIll(:,(ii-1)*10+jj);
    end
end

%% Plot figures

fig=figure;
set(fig,'Position', [100, 100, 1200, 800]);
subplot(2,3,1)
plot(SToWls(S),daylightGranadaOriginal);
title('Daylight Granada Original Spectra');

subplot(2,3,2)
plot(SToWls(S),daylightGranadaRescaled);
title('Daylight Granada Rescaled');

subplot(2,3,3)
plot(SToWls(S),newIlluminance);
title('New Randomly Generated Illuminance Spectra');

subplot(2,3,4)
hold on;
plot(IlluminantxyYGranada(1,:),IlluminantxyYGranada(2,:),'r.');
plot(IlluminantxyY(1,:),IlluminantxyY(2,:),'b*');
legend('Randomly generated','Granada','Location', 'southeast');

subplot(2,3,5)
image(theIlluminationImage)

%% This part saves the new Illuminants
% theWavelengths = SToWls(S);
% for ii = 1 : nIlluminances
% filename = ['illuminance_' num2str(ii)  '.spd'];
% fid = fopen(filename,'w');
% fprintf(fid,'%3d %3.6f\n',[theWavelengths,newIlluminance(:,ii)]');
% fclose(fid);
% end
