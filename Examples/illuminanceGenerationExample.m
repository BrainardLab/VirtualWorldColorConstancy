% Illuminance Generation example

% Clear
% clear; close all;

% Desired wl sampling
S = [380 5 81];
nIlluminances = 100;

theWavelengths = SToWls(S);
%% Load Granada Illumimace data
load daylightGranadaLong
daylightGranada = SplineSrf(S_granada,daylightGranada,S);
meanDaylightGranada = mean(daylightGranada);
daylightGranada = daylightGranada./repmat(meanDaylightGranada,[size(daylightGranada,1),1]);
figure; clf;
plot(SToWls(S),daylightGranada);

%% Analyze with respect to a linear model
B = FindLinMod(daylightGranada,6);
ill_granada_wgts = B\daylightGranada;
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
        ran_ill = B*ran_wgts;
        if (all(ran_ill >= 0))
            newIlluminance(:,newIndex) = ran_ill;
            newIndex = newIndex+1;
            OK = true;
        end
    end
end
figure; clf;
plot(SToWls(S),newIlluminance);

%% Load in the T_xyz1931 data for luminance sensitivity
theXYZData = load('T_xyz1931');
theLuminanceSensitivity = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);

%% Compute XYZ
IlluminantXYZ = theLuminanceSensitivity*newIlluminance;
SurfaceXYZ = theLuminanceSensitivity*newSurfaces;
IlluminantxyY = XYZToxyY(IlluminantXYZ);
SurfacexyY = XYZToxyY(SurfaceXYZ);

%% Convert to linear SRGB
SRGBPrimaryIll = XYZToSRGBPrimary(IlluminantXYZ);%
SRGBPrimarySur = XYZToSRGBPrimary(SurfaceXYZ);%
normSRGB = [SRGBPrimaryIll SRGBPrimarySur];
SRGBPrimaryNormIll = SRGBPrimaryIll/max(normSRGB(:));
SRGBPrimaryNormSur = SRGBPrimarySur/max(normSRGB(:));
SRGBIll = SRGBGammaCorrect(SRGBPrimaryNormIll,false)/255;
SRGBSur = SRGBGammaCorrect(SRGBPrimaryNormSur,false)/255;
for ii =1 :10
    for jj= 1:10
        theIlluminationImage(ii,jj,:)=SRGBIll(:,(ii-1)*10+jj);
        theSurfaceImage(ii,jj,:)=SRGBSur(:,(ii-1)*10+jj);
    end
end
% imwrite(theIlluminationImage, fullfile(pwd, 'Illuminations.png'));
% imwrite(theSurfaceImage, fullfile(pwd, 'Surfaces.png'));
% %% Make the images
% Ill=figure;
% image(theIlluminationImage); axis square; axis off;
% title('The Illuminants');
% print(Ill,'theIlluminants','-dpng');
% 
% Sur=figure;
% image(theSurfaceImage); axis square; axis off;
% title('The Surfaces');
% print(Sur,'theSurfaces','-dpng');
%%
figure; clf;
plot(IlluminantxyY(1,:),IlluminantxyY(2,:),'.');
%% 
theWavelengths = SToWls(S);
for ii = 1 : nIlluminances
filename = ['illuminance_' num2str(ii)  '.spd'];
fid = fopen(filename,'w');
fprintf(fid,'%3d %3.6f\n',[theWavelengths,newIlluminance(:,ii)]');
fclose(fid);
end
