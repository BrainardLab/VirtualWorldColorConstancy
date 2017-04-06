function makeFullMontageByCase(bucketFolder,luminanceLevels,reflectanceNumbers,cropImageHalfSize,RecipeConditions,varargin)
%
% makeFullMontageByCase(bucketFolder,luminanceLevels,reflectanceNumbers,cropImageHalfSize,RecipeConditions,varargin)
%
% This function returns the montage of full image, cropped image scaled and
% the statistics of luminance, hue and saturation for the set of images
% provided by the input
% bucketFolder : The path to the set of job folders
% jobFolder : Which fodler recipes to use
% luminanceLevels : The luminance levels to be used
% reflectanceNumbers : the reflectance numbers to be used
% RecipeConditions : The conditions used for this recipe, if left empty
%                   this output will have unspecified for all the columns.
%                   This should be given as a cell array with columns 
% {'Base Scene', 'Target Object','Target position', 'Illuminant Position',...
% 'Target Size', 'Illuminat Size', 'Other Object Spectra', 'Target Spectra',...
% ' Illuminant Spectra '}
%
% Example: 
% makeFullMontageByCase('~/Documents/Matlab',[0.2:0.4/9:0.6],[1:5],25,[],'jobFolder','Case32');

parser = inputParser();
parser.addParameter('jobFolder', '', @ischar);
parser.parse(varargin{:});
jobFolder = parser.Results.jobFolder;


toneMapFactor = 0;
if (isempty(RecipeConditions)) RecipeConditions = repmat({'unspecified'},[1,9]); end;


% Assign space for speed
LumCenter = zeros(size(luminanceLevels,2), size(reflectanceNumbers,2));
LumAvTarget = zeros(size(luminanceLevels,2), size(reflectanceNumbers,2));
LumAvOther = zeros(size(luminanceLevels,2), size(reflectanceNumbers,2));
HueAvTarget = zeros(size(luminanceLevels,2), size(reflectanceNumbers,2));
HueAvOther = zeros(size(luminanceLevels,2), size(reflectanceNumbers,2));
SaturationAvTarget = zeros(size(luminanceLevels,2), size(reflectanceNumbers,2));
SaturationAvOther = zeros(size(luminanceLevels,2), size(reflectanceNumbers,2));
trueLuminance = zeros(size(luminanceLevels,2), size(reflectanceNumbers,2));
trueHue = zeros(size(luminanceLevels,2), size(reflectanceNumbers,2));
trueSaturation = zeros(size(luminanceLevels,2), size(reflectanceNumbers,2));


% First make a figure
hFig2 = figure();
set(hFig2,'units','pixels', 'Position', [1 1 1000 1050]);

% Then make the table with the information about the recipe conditions
uitable('Data', RecipeConditions, 'ColumnName', {'Base Scene', 'Target Object','Target position', 'Illuminant Position',...
    'Target Size', 'Illuminat Size', 'Other Object Spectra', '  Target Spectra ',' Illuminant Spectra '},...
    'units','pixels','position', [50 990 860 50],'FontSize',15);

% We need the scale factor for sRGB images. Lets do this.
% While we are getting the scale factors, lets also get the luminance, hue
% and saturation

scaleFactor = 1;
whichLuminaceForMosaic = [1 5 10];
whichReflectancesForMosaic = [1:5];

for ii = 1:size(luminanceLevels,2)
    for jj = 1:size(reflectanceNumbers,2)
        
        % Get the path corresponding to the luminance level and reflectance
        recipeConds = getRecipeForCondition(luminanceLevels(ii),reflectanceNumbers(jj),...
            'jobFolder',jobFolder,'bucketFolder',bucketFolder);
        pathtoCroppedImage = fullfile(recipeConds.Working.fullPath,'images/Mitsuba/shapes/croppedImage.mat');
        imageData   = load(pathtoCroppedImage);
        [sRGBCroppedImage, XYZCroppedImage, ~, tempScaleFactor] = rtbMultispectralToSRGB(imageData.imageData,[400,10,31],...
            'toneMapFactor',toneMapFactor, 'isScale',true);
        if tempScaleFactor < scaleFactor
            scaleFactor = tempScaleFactor;
        end
        
        %% Get the target object position/pixels
        pathtoConeResponse = fullfile(recipeConds.Working.fullPath,'ConeResponse.mat');
        load(pathtoConeResponse);
        cropLocationC = recipe.processing.target.cropLocationC;
        cropLocationR = recipe.processing.target.cropLocationR;
        
        pathtoMaskImage = fullfile(recipeConds.Working.fullPath,'images/Mitsuba/radiance/mask.mat');
        targetMask = load(pathtoMaskImage);
        targetMask = targetMask.imageData;
        isTarget = 0 < sum(targetMask, 3);
        
        targetPixels = isTarget(cropLocationR:cropLocationR+2*cropImageHalfSize, ...
            cropLocationC:cropLocationC+2*cropImageHalfSize,:);
        
        %% True Luminance, Saturation and Hue
        trueColor = calculateTrueColor(luminanceLevels(ii), reflectanceNumbers(jj),recipeConds);
        trueLuminance(ii,jj) = trueColor(1);
        trueSaturation(ii,jj) = trueColor(2);
        trueHue(ii,jj) = trueColor(3);
        
        %% Target and Other object Average Color
        % Center Pixel luminance
        XYZCenter=double(XYZCroppedImage(floor(size(XYZCroppedImage,1)/2)+1,floor(size(XYZCroppedImage,2)/2)+1,:));
        XYZCenter=squeeze(XYZCenter);
        LumCenter(ii,jj) = XYZCenter(2);
        
        % Luminance
        LumAvTarget(ii,jj) = sum(sum(XYZCroppedImage(:,:,2).*targetPixels))/sum(targetPixels(:));
        LumAvOther(ii,jj) = sum(sum(XYZCroppedImage(:,:,2).*(~targetPixels)))/sum(~(targetPixels(:)));
        
        % Saturation
        imageColor = calculateImageColor(XYZCroppedImage);
        SaturationAvTarget(ii,jj) = sum(sum(imageColor(:,:,2).*targetPixels))/sum(sum(targetPixels));
        SaturationAvOther(ii,jj) = sum(sum(imageColor(:,:,2).*~targetPixels))/sum(sum(~targetPixels));
        
        % Hue
        allTargetPixelHue  = squeeze(imageColor(:,:,3)).*targetPixels;
        allOtherPixelHue   = squeeze(imageColor(:,:,3)).*(~targetPixels);
        
        HueAvTarget(ii,jj) = atan2(sum(sin(allTargetPixelHue(allTargetPixelHue~=0))),...
            sum(cos(allTargetPixelHue(allTargetPixelHue~=0))));
        HueAvOther(ii,jj) = atan2(sum(sin(allOtherPixelHue(allOtherPixelHue~=0))),...
            sum(cos(allOtherPixelHue(allOtherPixelHue~=0))));
        
        %% Plot the unscaled figures while we are in this loop

        switch ii
            case num2cell(whichLuminaceForMosaic)
                switch jj
                    case num2cell(whichReflectancesForMosaic)
                    first=axes(hFig2,'units','pixels','position', ...
                        [(find(whichReflectancesForMosaic==jj)-1)*95+20 (find(whichLuminaceForMosaic==ii)-1)*115+300 90 90]);
                    image(uint8(sRGBCroppedImage));
                    xlabel(num2str(reflectanceNumbers(jj)));
                    axis square;
                    set(gca,'xtick',[],'ytick',[]);
                    if (jj == 1)
                        ylabel(str2double(sprintf('%.2f',luminanceLevels(ii))));
                    end
                end
        end
        
    end
end

%% Plot the luminance, hue and saturation statistics
HueAvTarget(HueAvTarget<0)=HueAvTarget(HueAvTarget<0)+2*pi;
HueAvOther(HueAvOther<0)=HueAvOther(HueAvOther<0)+2*pi;

[~,name,~]=fileparts(jobFolder);
mkdir(fullfile('LuminanceAndHueValues',name));
save(fullfile('LuminanceAndHueValues',name,[name,'.mat']),...
                'LumCenter','LumAvTarget','LumAvOther','HueAvTarget','HueAvOther',...
                'SaturationAvTarget','SaturationAvOther','trueLuminance','trueHue','trueSaturation');

luminanceFigure = axes(hFig2,'units','pixels','position', [50 50 200 200]);            
errorbar(luminanceLevels,mean(LumCenter,2),std(LumCenter',1));
xlabel('Luminace Levels','FontSize',15);
ylabel('XYZ(2)','FontSize',15);
% title(name,'FontSize',15)
xlim([0.175,0.625]);
ylim([0,max(LumCenter(:))]);
axis square;
box on;

hold on;
errorbar(luminanceLevels,mean(LumAvTarget,2),std((LumAvTarget)',1),'r');
legend('Y_c','<Y>','location','northwest');
hold off;

luminanceRatioFigure = axes(hFig2,'units','pixels','position', [290 50 200 200]);            
axis square;
box on;
errorbar(luminanceLevels,mean(LumAvTarget./LumAvOther,2),std((LumAvTarget./LumAvOther)',1));
xlabel('Luminace Levels','FontSize',15);
ylabel('Average Y Ratio ','FontSize',15);
% title(name,'FontSize',15)
xlim([0.175,0.625]);
ylim([0,3]);

HueFigure = axes(hFig2,'units','pixels','position', [525 50 200 200]);            
axis square;
box on;
hold on;
plot(trueHue(:),HueAvTarget(:),'.','MarkerSize',20);
plot(trueHue(:),HueAvOther(:),'r.','MarkerSize',20);
xlabel('True Hue','FontSize',15);
ylabel('<Target Hue>','FontSize',15);
% title(name,'FontSize',15)
legend('Target','Other');
xlim([0,2*pi]);
ylim([0,2*pi]);
hold off;

SaturationFigure = axes(hFig2,'units','pixels','position', [775 50 200 200]);            
axis square;
box on;
hold on;
plot(trueSaturation(:),SaturationAvTarget(:),'.','MarkerSize',20)
plot(trueSaturation(:),SaturationAvOther(:),'.','MarkerSize',20)
xlabel('True Saturation','FontSize',15);
ylabel('<Target Saturation>','FontSize',15);
% title(name,'FontSize',15)
legend('Target','Other');

%% Now plot the full image and the scaled cropped image            
for ii = 1:size(whichLuminaceForMosaic,2)
    for jj = 1:size(whichReflectancesForMosaic,2)
        
        % Get the path corresponding to the luminance level and reflectance
        recipeConds = getRecipeForCondition(luminanceLevels(whichLuminaceForMosaic(ii)),...
                    reflectanceNumbers(whichReflectancesForMosaic(jj)),...
                    'jobFolder',jobFolder,'bucketFolder',bucketFolder);
        
        % Get the cropped image
        pathtoCroppedImage = fullfile(recipeConds.Working.fullPath,'images/Mitsuba/shapes/croppedImage.mat');
        croppedImageData   = load(pathtoCroppedImage);
        [sRGBCropped, ~, ~, ~] = rtbMultispectralToSRGB(croppedImageData.imageData,[400,10,31],...
            'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);

        first=axes(hFig2,'units','pixels','position', ...
            [(jj-1)*95+520 (ii-1)*115+300 90 90]);
        image(uint8(sRGBCropped));
        xlabel(num2str(reflectanceNumbers(whichReflectancesForMosaic(jj))));
        axis square;
        set(gca,'xtick',[],'ytick',[]);
        if (jj == 1)
            ylabel(str2double(sprintf('%.2f',luminanceLevels(whichLuminaceForMosaic(ii)))));
        end
        
        % Get the Full image
        pathtoFullImage = fullfile(recipeConds.Working.fullPath,'images/Mitsuba/radiance/normal.mat');
        FullImageData   = load(pathtoFullImage);
        [sRGBFull, ~, ~, ~] = rtbMultispectralToSRGB(FullImageData.imageData,[400,10,31],...
            'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);

        first=axes(hFig2,'units','pixels','position', ...
            [(jj-1)*165+30 (ii-1)*115+650 150 100]);
        image(uint8(sRGBFull));
        xlabel(num2str(reflectanceNumbers(whichReflectancesForMosaic(jj))));
        set(gca,'xtick',[],'ytick',[]);
        if (jj == 1)
            ylabel(str2double(sprintf('%.2f',luminanceLevels(whichLuminaceForMosaic(ii)))));
        end
        
    end
end

figFullMontage = fullfile(bucketFolder,jobFolder,['FullMontage.pdf']);
set(gcf,'PaperPositionMode','auto');
save2pdf(figFullMontage);
close;

