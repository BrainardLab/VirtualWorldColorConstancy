function Figure7(folderToStore)
%Figure7(folderToStore)
% Function to generate some surface target reflectance samples and plot them.
%
% Input 
% folderToStore : Folder where the figures should be stored.
%

if (~exist(folderToStore))
    mkdir(folderToStore)
end

% Desired wl sampling
nSurfaces = 100;

S = [400 5 61];
theWavelengths = SToWls(S);
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

%% Generate some new surfaces
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

%% load D65 for estimating XYZ 
theIlluminantData = load('spd_D65');
D65 = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
D65 = D65/mean(D65);

%% Load in the T_xyz1931 data for luminance sensitivity
theXYZData = load('T_xyz1931');
theLuminanceSensitivity = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);
theLuminanceSensitivityIll = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);

%% Compute XYZ
SurfaceXYZ = theLuminanceSensitivityIll*diag(D65)*newSurfaces;
SurfacexyY = XYZToxyY(SurfaceXYZ);
XYZsurAll = theLuminanceSensitivity*diag(D65)*sur_all;
xyYSurall = XYZToxyY(XYZsurAll);

%% Convert to linear SRGB
SRGBPrimaryIll = XYZToSRGBPrimary(SurfaceXYZ);% Primary Illuminance 
SRGBPrimaryNormIll = SRGBPrimaryIll/max(SRGBPrimaryIll(:));
SRGBIll = SRGBGammaCorrect(SRGBPrimaryNormIll,false)/255;
    
%% Reshape the matrices for plotting as squares

for ii =1 :10
    for jj= 1:10
        theSurfaceImage(ii,jj,:)=SRGBIll(:,(ii-1)*10+jj);
    end
end

%% Plot figures
FS = 25;
FSTitle = 15;

fig=figure;
set(fig,'Position', [100, 100,550, 500]);
hold on;
box on; axis square;
for ii = 1 : size(sur_all,2)
    rescaledFig = plot(SToWls(S),sur_all(:,ii),'k');
    rescaledFig.Color(4)=0.2;
end
% title('Natural Surface Spectra','FontSize',FSTitle);
xlabel('Wavelength (nm)','FontSize',FS);
ylabel('Reflectance','FontSize',FS)
set(gca,'FontSize',FS);
% title('Munsell and Vrhel Data','FontSize',FS);
ylimit=get(gca,'ylim');
yticks([0:0.2:1]);
yticklabels({'0.0' '0.2' '0.4' '0.6' '0.8' '1.0'});
save2pdf([folderToStore,'/Figure7_a.pdf'],fig,600);
close;

fig=figure;
set(fig,'Position', [100, 100,550, 500]);
hold on;
box on; axis square;
for ii = 1 : size(newSurfaces,2)
    rescaledFig = plot(SToWls(S),newSurfaces(:,ii),'k');
    rescaledFig.Color(4)=0.4;
end
ylim([0 1]);
yticks([0:0.2:1]);
yticklabels({'0.0' '0.2' '0.4' '0.6' '0.8' '1.0'});
xlabel('Wavelength (nm)','FontSize',FS);
ylabel('Reflectance','FontSize',FS)
set(gca,'FontSize',FS);
% title('Statistical model','FontSize',FS);
set(gca,'FontSize',FS);
save2pdf([folderToStore,'/Figure7_b.pdf'],fig,600);
close;

%%
fig=figure;
set(fig,'Position', [100, 100,550, 500]);
hold on;
box on; axis square;
plotxy = plot(xyYSurall(1,:),xyYSurall(2,:),'k.','MarkerSize',10);
plot(SurfacexyY(1,:),SurfacexyY(2,:),'*r','MarkerFaceColor','r');
% plot(TargetxyY(1,:),TargetxyY(2,:),'gs','MarkerFaceColor','g','MarkerSize',5);
xlabel('CIE x chromaticity','FontSize',FS);
ylabel('CIE y chromaticity','FontSize',FS)
set(gca,'FontSize',FS);
legend({'Natural reflectance','Random samples'}, 'Location', 'southeast','FontSize',20);
axis square;
save2pdf([folderToStore,'/Figure7_c.pdf'],fig,600);
close;

%%
fig=figure;
set(fig,'Position', [100, 100, 550, 500]);
hold on;
axis square;
image(theSurfaceImage);
% title('sRGB Rendition of $\tilde{R}(\lambda)$','interpreter','latex','FontSize',FSTitle);
xlim([0.5 10.5]);
ylim([0.5 10.5]);
set(gca,'FontSize',FS);
axis off;
save2pdf([folderToStore,'/Figure7_d.pdf'],fig,600);
close;
end