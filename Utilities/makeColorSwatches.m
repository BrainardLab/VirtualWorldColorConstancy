function makeColorSwatches(pathToFolder)

% Load the data
NReflectance = 100;

for iterSpectraNumber = 1:NReflectance
   filename = sprintf('reflectance_%03d.spd',iterSpectraNumber);
   [wav, tempSpectrum] = rtbReadSpectrum(fullfile(pathToFolder,filename));
   newSurfaces(:,iterSpectraNumber) = tempSpectrum;
end

theWavelengths = wav;

%% Load D65
theIlluminantData = load('spd_D65');
theIlluminant = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
theIlluminant = theIlluminant/mean(theIlluminant);

%% Load in the T_xyz1931 data for luminance sensitivity
theXYZData = load('T_xyz1931');
theLuminanceSensitivity = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);
theLuminanceSensitivityIll = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);

%% Compute XYZ
SurfaceXYZ = theLuminanceSensitivityIll*diag(theIlluminant)*newSurfaces;

%% Convert to linear SRGB
SRGBXYZ = XYZToSRGBPrimary(SurfaceXYZ);% Primary Illuminance 
SRGBNorm = SRGBXYZ/max(SRGBXYZ(:));
SRGBGramaCorrect = SRGBGammaCorrect(SRGBNorm,false)/255;
    
%% Reshape the matrices for plotting as squares

for ii =1 :10
    for jj= 1:10
        theSurfaceImage(ii,jj,:)=SRGBGramaCorrect(:,(ii-1)*10+jj);
    end
end


%%
FS = 25;
FSTitle = 15;
fig=figure;
set(fig,'Position', [100, 100, 1000, 500]);
subplot(1,2,1);
hold on;
box on; axis square;
for ii = 1 : size(newSurfaces,2)
    rescaledFig = plot(theWavelengths,newSurfaces(:,ii),'k','linewidth',0.1);
    rescaledFig.Color(4)=0.6;
end
% title('Natural Surface Spectra','FontSize',FSTitle);
xlabel('Wavelength (nm)','FontSize',FS);
ylabel('Reflectance','FontSize',FS)
set(gca,'FontSize',FS);

subplot(1,2,2);
hold on;
axis square;
image(theSurfaceImage);
% title('sRGB Rendition of $\tilde{R}(\lambda)$','interpreter','latex','FontSize',FSTitle);
xlim([0.5 10.5]);
ylim([0.5 10.5]);
axis off;

end
