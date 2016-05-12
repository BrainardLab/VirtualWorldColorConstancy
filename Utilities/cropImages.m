clear;

load('/Users/vijaysingh/test/ToyVirtualWorld_4/Working/luminance-0_90-reflectance-002-SmallBall-CheckerBoard/images/Mitsuba/radiance/mask.mat')

%%

[r,c,v] = find(sum(imageData,3));
r = unique(r);c = unique(c);

targetTop = min(r);
targetBottom = max(r);
targetLeft = min(c);
targetRight = max(c);

targetCenterR = targetTop + floor((targetBottom-targetTop)/2);
targetCenterC = targetLeft + floor((targetRight-targetLeft)/2);

cropLocationR = targetCenterR - 25;
cropLocationC = targetCenterC - 25;

%%
load('/Users/vijaysingh/test/ToyVirtualWorld/Working/luminance-0_90-reflectance-001-BigBall-Library/images/Mitsuba/radiance/normal.mat');

croppedImage = imageData(cropLocationR:cropLocationR+50,cropLocationC:cropLocationC+50,:);
figure;
subplot(2,1,1);
imagesc(sum(imageData,3));
cax=caxis;
subplot(2,1,2);
imagesc(sum(croppedImage,3));
caxis(cax);