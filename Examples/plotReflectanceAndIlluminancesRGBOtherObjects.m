% This script generates the illuminace and then plot the illuminances and
% the reflectances for other objects
clear;
nIlluminances = 100;

% Desired wl sampling
S = [400 5 61];
theWavelengths = SToWls(S);
%% Load Granada Illumimace data
load daylightGranadaLong
daylightGranadaOriginal = SplineSrf(S_granada,daylightGranada,S);
% maxDaylightGranada = max(daylightGranadaOriginal);  
% daylightGranadaRescaled = daylightGranadaOriginal./repmat(maxDaylightGranada,[size(daylightGranadaOriginal,1),1]);
% meanDaylightGranada = mean(daylightGranadaOriginal);  
% daylightGranadaRescaled = daylightGranadaOriginal./repmat(meanDaylightGranada,[size(daylightGranadaOriginal,1),1]);
lengthDaylightGranada = sqrt(sum(daylightGranadaOriginal.*daylightGranadaOriginal));  
daylightGranadaRescaled = daylightGranadaOriginal./repmat(lengthDaylightGranada,[size(daylightGranadaOriginal,1),1]);
meandaylightGranadaRescaled = mean(daylightGranadaRescaled,2);
daylightGranadaRescaledMeanSubtracted = bsxfun(@minus,daylightGranadaRescaled,meandaylightGranadaRescaled);


%% Analyze with respect to a linear model
B = FindLinMod(daylightGranadaRescaled,6);
ill_granada_wgts = B\daylightGranadaRescaled;
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
theLuminanceSensitivityIll = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);

%% Load in the required Surfaces
theIlluminantData = load('spd_D65');
theIlluminant = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
theIlluminant = theIlluminant/(theLuminanceSensitivityIll(2,:)*theIlluminant);
%% Compute XYZ 
IlluminantXYZ = theLuminanceSensitivityIll*newIlluminance;
SurfaceXYZ = theLuminanceSensitivityIll*newSurfaces;
SurfaceXYZD65 = theLuminanceSensitivityIll*(bsxfun(@times,newSurfaces,theIlluminant));
IlluminantxyY = XYZToxyY(IlluminantXYZ);
SurfacexyY = XYZToxyY(SurfaceXYZ);
SurfacexyYD65 = XYZToxyY(SurfaceXYZD65);

%% Convert to linear SRGB
SRGBPrimaryIll = XYZToSRGBPrimary(IlluminantXYZ);% Primary Illuminance 
SRGBPrimarySur = XYZToSRGBPrimary(SurfaceXYZ);% Bare Surfaces
SRGBPrimarySurD65 = XYZToSRGBPrimary(SurfaceXYZD65);% Surfaces Under D65
SRGBPrimaryNormIll = SRGBPrimaryIll/max(SRGBPrimaryIll(:));
SRGBPrimaryNormSur = SRGBPrimarySur/max(SRGBPrimarySur(:));
SRGBPrimaryNormSurD65 = SRGBPrimarySurD65/max(SRGBPrimarySurD65(:));
SRGBIll = SRGBGammaCorrect(SRGBPrimaryNormIll,false)/255;
SRGBSur = SRGBGammaCorrect(SRGBPrimaryNormSur,false)/255;
SRGBSurD65 = SRGBGammaCorrect(SRGBPrimaryNormSurD65,false)/255;

    
%% Reshape the matrices for plotting as squares

for ii =1 :10
    for jj= 1:10     
        theIlluminationImage(ii,jj,:)=SRGBIll(:,(ii-1)*10+jj);
    end
end

nLuminanceLevels=10;
nSurfaceAtEachLuminace=10;

for ii =1 : nLuminanceLevels
    for jj= 1 : nSurfaceAtEachLuminace
        theSurfaceImage(ii,jj,:)=SRGBSur(:,(ii-1)*nSurfaceAtEachLuminace+jj);
        theSurfaceImageD65(ii,jj,:)=SRGBSurD65(:,(ii-1)*nSurfaceAtEachLuminace+jj);
    end
end
%% Make the images
figure;
subplot(2,3,1)
image(theIlluminationImage); axis square;
title('The Illuminants');

subplot(2,3,2)
image(theSurfaceImage); axis off;
title('The Surfaces Under constact 1 Illumination');

subplot(2,3,3)
image(theSurfaceImageD65); axis off;
title('The Surfaces Under D65');

%% Create figures for surfaces at three random illuminances
    randIlluminaceIndices = ceil(rand(1,3)*100);
for i =1 : 3
    SurfaceXYZrandIll = theLuminanceSensitivityIll*(bsxfun(@times,newSurfaces,newIlluminance(:,randIlluminaceIndices(i))));
    SurfacexyYrandIll = XYZToxyY(SurfaceXYZrandIll);
    SRGBPrimarySurrandIll = XYZToSRGBPrimary(SurfaceXYZrandIll);
    SRGBPrimaryNormSurrandIll = SRGBPrimarySurrandIll/max(SRGBPrimarySurrandIll(:));
    SRGBSurrandIll = SRGBGammaCorrect(SRGBPrimaryNormSurrandIll,false)/255;
    
    for ii =1 : nLuminanceLevels
        for jj= 1 : nSurfaceAtEachLuminace
            theSurfaceImagerandIll(ii,jj,:)=SRGBSurrandIll(:,(ii-1)*nSurfaceAtEachLuminace+jj);
        end
    end
    subplot(2,3,3+i)
    image(theSurfaceImagerandIll); axis off;
    title(['The Surfaces with Fixed Luminance under Illuminant ',num2str(randIlluminaceIndices(i))]);
end  

%%
figure;
hold on;
plot(SurfacexyY(1,:),SurfacexyY(2,:),'b+')