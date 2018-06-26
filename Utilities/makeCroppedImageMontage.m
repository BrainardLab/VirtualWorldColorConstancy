function makeCroppedImageMontage(pathToFolder,luminanceLevels,reflectanceNumbers,RecipeName)
% makeCroppedImageMontage(pathToFolder,luminanceLevels,reflectanceNumbers,RecipeConditions,varargin)
%
% Usage: 
%     makeCroppedImageMontage(fullfile('/Volumes/OWSHD','Dropbox (Aguirre-Brainard Lab)','/IBIO_analysis/VirtualWorldColorConstancy/ExampleOutput'),[0.2 0.4 0.6], [1:5],[])
%
% Description:
%     This function returns the montage of scaled cropped images.
%     The crop location is hard-coded for the library scene for an image of
%     size 960 by 1280. Need to change it for different size image.
%
% Input:
%   pathToFolder = path to the base folder that contains the working folder
%   luminanceLevels = luminance levels for which the images are shown
%   reflectanceNumber = reflectance numbers of the images that are shown
%   RecipeName = Recipe name to set the title of the image
%
% VS wrote this
%

toneMapFactor = 0;

% First make a figure
hFig2 = figure();
set(hFig2,'units','pixels', 'Position', [1 1 550 360]);

% We need the scale factor for sRGB images. Lets do this.

scaleFactor = 1;
whichLuminaceForMosaic = [1 2 3];
whichReflectancesForMosaic = [1:5];

% for ii = 1:size(luminanceLevels,2)
%     for jj = 1:size(reflectanceNumbers,2)
%         
%         % Get the path corresponding to the luminance level and reflectance
%         namePattern = FormatRecipeName(luminanceLevels(ii),reflectanceNumbers(jj), '*', '*');        
%         pathToWorkingFolder = fullfile(pathToFolder,'Working');
%         infoRecipe = dir(fullfile(pathToWorkingFolder,namePattern));
%         pathtoFullImage = fullfile(pathToWorkingFolder,infoRecipe.name,'renderings/Mitsuba/normal.mat');
%         FullImageData   = load(pathtoFullImage);
%         imageData   = FullImageData.multispectralImage;
% %         croppedImage = imageData(380:580,540:740,:);
%         croppedImage = imageData(100:140,140:180,:);
%         [sRGBCroppedImage, ~, ~, tempScaleFactor] = rtbMultispectralToSRGB(croppedImage,[400,10,31],...
%             'toneMapFactor',toneMapFactor, 'isScale',true);
%         if tempScaleFactor < scaleFactor
%             scaleFactor = tempScaleFactor;
%         end
%                 
%     end
% end

scaleFactor = 0.005;
%% Now plot the cropped image            
for ii = 1:size(whichLuminaceForMosaic,2)
    for jj = 1:size(whichReflectancesForMosaic,2)
        
        % Get the path corresponding to the luminance level and reflectance
        namePattern = FormatRecipeName(luminanceLevels(whichLuminaceForMosaic(ii)),...
            reflectanceNumbers(whichReflectancesForMosaic(jj)), '*', '*');        
        pathToWorkingFolder = fullfile(pathToFolder,'Working');
        infoRecipe = dir(fullfile(pathToWorkingFolder,namePattern));
        pathtoFullImage = fullfile(pathToWorkingFolder,infoRecipe.name,'renderings/Mitsuba/normal.mat');
        FullImageData   = load(pathtoFullImage);
        imageData   = FullImageData.multispectralImage;
        croppedImage = imageData(380:580,540:740,:);
%         croppedImage = imageData(100:140,140:180,:);
        [sRGBCropped, ~, ~, ~] = rtbMultispectralToSRGB(croppedImage,[400,10,31],...
            'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);

        first=axes(hFig2,'units','pixels','position', ...
            [(jj-1)*95+60 (ii-1)*95+70 90 90]);
        image(uint8(sRGBCropped));
        if (ii ==1)
            if (jj==3)
                xlabel({num2str(reflectanceNumbers(whichReflectancesForMosaic(jj))),'Image index'},'FontSize',20);
            else
                xlabel(num2str(reflectanceNumbers(whichReflectancesForMosaic(jj))),'FontSize',20);
            end
        end
        axis square;
        set(gca,'xtick',[],'ytick',[]);
        if (jj == 1)
            if ii ==2
                ylabel([{'LRV',str2double(sprintf('%.2f',luminanceLevels(whichLuminaceForMosaic(ii))))}],'FontSize',20);
            else
                ylabel(str2double(sprintf('%.2f',luminanceLevels(whichLuminaceForMosaic(ii)))),'FontSize',20);
            end
        end                
    end
end

figFullMontage = fullfile(pathToFolder,'CroppedImageMontage_Scale_0_5.eps');
set(gcf,'PaperPositionMode','auto');
save2eps(figFullMontage,gcf,600);
close;

