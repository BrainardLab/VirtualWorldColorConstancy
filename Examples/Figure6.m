function Figure6(folderToStore)
%Figure6(folderToStore)
% Function to generate some illuminant samples and plot them.
% Input 
% folderToStore : Folder where the figures should be stored.
%

if (~exist(folderToStore))
    mkdir(folderToStore)
end

% Desired wl sampling
nIlluminances = 100;

S = [400 5 61];
theWavelengths = SToWls(S);
%% Load Granada Illumimace data
load daylightGranadaLong
daylightGranadaOriginal = SplineSrf(S_granada,daylightGranada,S);

% Rescale spectrum by its mean
meanDaylightGranada = mean(daylightGranadaOriginal);
daylightGranadaRescaled = bsxfun(@rdivide,daylightGranadaOriginal,meanDaylightGranada);

%% Center the data for PCA
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

scaling = 0;

for i = 1:nNewIlluminaces
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        ran_ill = B*ran_wgts+meandaylightGranadaRescaled;
        if (all(ran_ill >= 0))
            newIlluminance(:,newIndex) = ran_ill;
            if scaling
                newIlluminance(:,newIndex) = newIlluminance(:,newIndex)*...
                        (meanDaylightGranada(randi(length(meanDaylightGranada))));
            end
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
SRGBPrimaryIll = XYZToSRGBPrimary(IlluminantXYZ); % Primary Illuminance 
SRGBPrimaryNormIll = SRGBPrimaryIll/max(SRGBPrimaryIll(:));
SRGBIll = SRGBGammaCorrect(SRGBPrimaryNormIll,false)/255;
    
%% Reshape the matrices for plotting as squares

for ii =1 :10
    for jj= 1:10
        theIlluminationImage(ii,jj,:)=SRGBIll(:,(ii-1)*10+jj);
    end
end

%% Plot figures
FS = 25;
FSTitle = 15;

% Figure 6 a
fig=figure;
box on; axis square; hold on;
set(fig,'Position', [100, 100,550, 500]);
for ii = 1 : size(daylightGranadaRescaled,2)
    rescaledFig = plot(SToWls(S),daylightGranadaRescaled(:,ii),'k');
    rescaledFig.Color(4)=0.1;
end
% title('Rescaled Granada Spectra','FontSize',FSTitle);
xlabel('Wavelength (nm)','FontSize',FS);
ylabel('Normalized Irradiance','FontSize',FS)
set(gca,'FontSize',FS);
% title('Granada data','FontSize',FS);
ylim([0 2]);
yticks([0 0.5 1 1.5 2]);
yticklabels({'0.0' '0.5' '1.0' '1.5' '2.0'});
axis square;
save2pdf([folderToStore,'/Figure6_a.pdf'],fig,1000);
close;

% Figure 6 b
fig=figure;
box on; axis square; hold on;
set(fig,'Position', [100, 100,550, 500]);
for ii = 1 : size(newIlluminance,2)
    rescaledFig2 = plot(SToWls(S),newIlluminance(:,ii),'k');
    rescaledFig2.Color(4)=0.3;
end
ylim([0 2]);
yticks([0 0.5 1 1.5 2]);
yticklabels({'0.0' '0.5' '1.0' '1.5' '2.0'});
% title('Statistical model','FontSize',FS);
xlabel('Wavelength (nm)','FontSize',FS);
ylabel('Normalized Irradiance','FontSize',FS)
set(gca,'FontSize',FS);
axis square;
save2pdf([folderToStore,'/Figure6_b.pdf'],fig,1000);
close;

% Figure 6 c
fig=figure;
set(fig,'Position', [100, 100,550, 500]);
hold on;
box on; axis square;
plot(IlluminantxyYGranada(1,:),IlluminantxyYGranada(2,:),'k.');
plot(IlluminantxyY(1,:),IlluminantxyY(2,:),'r*');
xticks([0.2 0.25 0.3 0.35 0.4]);
xticklabels({'0.20' '0.25' '0.30' '0.35' '0.40'});
yticks([0.25 0.3 0.35 0.4]);
yticklabels({'0.25' '0.30' '0.35' '0.40'});
xlabel('CIE x chromaticity','FontSize',FS);
ylabel('CIE y chromaticity','FontSize',FS)
legend('Normalized dataset','Random samples','Location', 'northwest');
set(gca,'FontSize',FS);
axis square;
save2pdf([folderToStore,'/Figure6_c.pdf'],fig,1000);
close;

% Figure 6d
fig=figure;
box on; axis square;
set(fig,'Position', [100, 100,550, 500]);
image(theIlluminationImage);
% title('sRGB Rendition of $\tilde{I}(\lambda)$','interpreter','latex','FontSize',FSTitle);
set(gca,'FontSize',FS);
axis square;
axis off;
save2pdf([folderToStore,'/Figure6_d.pdf'],fig,1000);
close;
end
