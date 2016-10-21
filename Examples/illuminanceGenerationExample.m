% Illuminance Generation example
%
% This script generates the Illumiance for the base scenes. The
% illuminace spectra are generated using the library obtained from the
% granada daylight spectra.
%
% Clear
clear; %close all;

% Desired wl sampling
nIlluminances = 1000;
rescaling = 0;  % O no rescaling
                % 1 rescaling

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
% meanDaylightGranada = mean(daylightGranadaOriginal);  
% daylightGranadaMeanCentered = bsxfun(@minus,daylightGranadaOriginal,meanDaylightGranada);

% Normalize the spectra by their L2 norm
lengthDaylightGranada = sqrt(sum(daylightGranadaOriginal.*daylightGranadaOriginal));  
daylightGranadaRescaled = daylightGranadaOriginal./repmat(lengthDaylightGranada,[size(daylightGranadaOriginal,1),1]);

% Add the mean value rescaled by the L2 norm
% daylightGranadaRescaled = bsxfun(@plus,daylightGranadaRescaled,meanDaylightGranada./lengthDaylightGranada);

% Center the data for PCA
if ~ rescaling 
    daylightGranadaRescaled = daylightGranadaOriginal;
end
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
%%
wgts_New=B'*bsxfun(@minus,newIlluminance,meandaylightGranadaRescaled);
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
title('Daylight Granada Spectra');
xlabel('Wavelength (nm)')
ylabel('Spectral Power Distribution')
ylimit=get(gca,'ylim');

subplot(2,3,2)
plot(SToWls(S),daylightGranadaRescaled);
title('Daylight Granada Rescaled');
xlabel('Wavelength (nm)')
ylabel('Rescaled Spectral Power Distribution')
ylimit=get(gca,'ylim');
ylim(ylimit);

subplot(2,3,3)
plot(SToWls(S),newIlluminance);
ylim(ylimit);
title('New Randomly Generated Illuminance Spectra');
xlabel('Wavelength (nm)')
ylabel('Rescaled Spectral Power Distribution')

subplot(2,3,4)
hold on;
plot(IlluminantxyYGranada(1,:),IlluminantxyYGranada(2,:),'r.');
plot(IlluminantxyY(1,:),IlluminantxyY(2,:),'b*');
legend('Randomly generated','Granada','Location', 'southeast');
title('xy chromaticity diagram');
xlabel('x')
ylabel('y')
legend('Granda Rescaled','New Illuminaces','Location', 'northwest');


subplot(2,3,5)
hold on;
plot(ill_granada_wgts(1,:),ill_granada_wgts(2,:),'.');
plot(wgts_New(1,:),wgts_New(2,:),'*');
title('Projection along first two PCs');
xlabel('PC1')
ylabel('PC2')
legend('Granda Rescaled','New Illuminaces','Location', 'northwest');

subplot(2,3,6)
image(theIlluminationImage);
axis off;

%% This part saves the new Illuminants
% theWavelengths = SToWls(S);
% for ii = 1 : nIlluminances
% filename = ['illuminance_' num2str(ii)  '.spd'];
% fid = fopen(filename,'w');
% fprintf(fid,'%3d %3.6f\n',[theWavelengths,newIlluminance(:,ii)]');
% fclose(fid);
% end
