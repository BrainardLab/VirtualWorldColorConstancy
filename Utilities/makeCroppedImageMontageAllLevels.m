function makeCroppedImageMontageAllLevels(folderName, croppedImageSize, luminanceLevels, reflectanceNumbers, scaleFactor)
% makeCroppedImageMontageAllLevels(pathToFolder,croppedImageSize,luminanceLevels,reflectanceNumbers,RecipeConditions,varargin)
%
% Usage: 
%     makeCroppedImageMontage('StimuliFixedFlatTargetShapeFixedIlluminantBetweentrialBkGndVariation', 201, [0.35 0.4 0.45], [1:5],0.005)
%
% Description:
%     This function returns the montage of scaled cropped images.
%     The crop location is hard-coded for the library scene for an image of
%     size 960 by 1280. Need to change it for different size image.
%
% Input:
%   pathToFolder = path to the base folder that contains the working folder
%   croppedImageSize = size of cropped image
%   luminanceLevels = luminance levels for which the images are shown
%   reflectanceNumber = reflectance numbers of the images that are shown
%   RecipeName = Recipe name to set the title of the image
%
% VS wrote this
%

toneMapFactor = 0;
projectName = 'VirtualWorldColorConstancy';
% First make a figure
hFig2 = figure();
set(hFig2,'units','pixels', 'Position', [1 1 (length(reflectanceNumbers))*95+100 (length(luminanceLevels))*95+100]);

% We need the scale factor for sRGB images. Lets do this.
whichLuminaceForMosaic = (1:length(luminanceLevels));
whichReflectancesForMosaic = [1:length(reflectanceNumbers)];

%% Now plot the cropped image            
for ii = 1:size(whichLuminaceForMosaic,2)
    for jj = 1:size(whichReflectancesForMosaic,2)
        
        % Get the path corresponding to the luminance level and reflectance
        namePattern = FormatRecipeName(luminanceLevels(whichLuminaceForMosaic(ii)),...
            reflectanceNumbers(whichReflectancesForMosaic(jj)), '*', '*');        
        pathToWorkingFolder = fullfile(getpref(projectName, 'baseFolder'),folderName,'Working');
        infoRecipe = dir(fullfile(pathToWorkingFolder,namePattern));
        pathtoFullImage = fullfile(pathToWorkingFolder,infoRecipe.name,'ConeResponse.mat');
        FullImageData   = load(pathtoFullImage);
        croppedImage = FullImageData.recipe.processing.croppedImage;;
        [sRGBCropped, ~, ~, ~] = rtbMultispectralToSRGB(croppedImage,[400,10,31],...
            'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);

        first=axes(hFig2,'units','pixels','position', ...
            [(jj-1)*95+60 (ii-1)*95+70 90 90]);
        image(uint8(sRGBCropped));
        if (ii ==1)
            if (jj == round(length(reflectanceNumbers)/2))
                xlabel({num2str(reflectanceNumbers(whichReflectancesForMosaic(jj))),'Image index'},'FontSize',20);
            else
                xlabel(num2str(reflectanceNumbers(whichReflectancesForMosaic(jj))),'FontSize',20);
            end
        end
        axis square;
        set(gca,'xtick',[],'ytick',[]);
        if (jj == 1)
            if ii == round(length(luminanceLevels)/2)
                ylabel([{'LRV',str2double(sprintf('%.2f',luminanceLevels(whichLuminaceForMosaic(ii))))}],'FontSize',20);
            else
                ylabel(str2double(sprintf('%.2f',luminanceLevels(whichLuminaceForMosaic(ii)))),'FontSize',20);
            end
        end                
    end
end

figFullMontage = fullfile(getpref(projectName, 'baseFolder'),folderName,...
    ['CroppedImageMontage_Scale_',num2str(scaleFactor,'%.4f'),'.pdf']);
set(gcf,'PaperPositionMode','auto');
save2pdf(figFullMontage,gcf,600);
close;

