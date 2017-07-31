function makeFullMontage(pathToFolder,luminanceLevels,reflectanceNumbers,RecipeName)
%
% makeFullMontageByCase(pathToFolder,luminanceLevels,reflectanceNumbers,RecipeConditions,varargin)
%
% This function returns the montage of full image, cropped image scaled and
% the statistics of luminance, hue and saturation for the set of images
% provided by the input
% pathToFolder: The path to the job folder
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
% makeFullMontageByCase('/Volumes/OWSHD/Dropbox (Aguirre-Brainard Lab)/IBIO_analysis/VirtualWorldColorConstancy/FixedTargetShapeFixedIlluminantFixedBkGnd',[0.2:0.4/9:0.6],[1:5],25,[]);

toneMapFactor = 0;

% First make a figure
hFig2 = figure();
set(hFig2,'units','pixels', 'Position', [1 1 1000 1050]);

% % Then make the table with the information about the recipe conditions
% uitable('Data', RecipeConditions, 'ColumnName', {'Base Scene', 'Target Object','Target position', 'Illuminant Position',...
%     'Target Size', 'Illuminat Size', 'Other Object Spectra', '  Target Spectra ',' Illuminant Spectra '},...
%     'units','pixels','position', [50 990 860 50],'FontSize',15);
annotation('textbox','units','pixels','position',[50 990 860 50],'String',RecipeName,...
    'BackgroundColor',[1 1 1],'FitBoxToText','on','FontSize',20,'HorizontalAlignment','center');

% We need the scale factor for sRGB images. Lets do this.

scaleFactor = 1;
whichLuminaceForMosaic = [1 5 10];
whichReflectancesForMosaic = [1:5];

for ii = 1:size(luminanceLevels,2)
    for jj = 1:size(reflectanceNumbers,2)
        
        % Get the path corresponding to the luminance level and reflectance
        namePattern = FormatRecipeName(luminanceLevels(ii),reflectanceNumbers(jj), '*', '*');        
        pathToWorkingFolder = fullfile(pathToFolder,'Working');
        infoRecipe = dir(fullfile(pathToWorkingFolder,namePattern));
        pathtoRecipe = fullfile(pathToWorkingFolder,infoRecipe.name,'ConeResponse.mat');
        imageData   = load(pathtoRecipe);
        croppedImage = imageData.recipe.processing.croppedImage;
        [sRGBCroppedImage, ~, ~, tempScaleFactor] = rtbMultispectralToSRGB(croppedImage,[400,10,31],...
            'toneMapFactor',toneMapFactor, 'isScale',true);
        if tempScaleFactor < scaleFactor
            scaleFactor = tempScaleFactor;
        end
                
        
        %% Plot the unscaled figures while we are in this loop

        switch ii
            case num2cell(whichLuminaceForMosaic)
                switch jj
                    case num2cell(whichReflectancesForMosaic)
                    first=axes(hFig2,'units','pixels','position', ...
                        [(find(whichReflectancesForMosaic==jj)-1)*95+30 (find(whichLuminaceForMosaic==ii)-1)*115+300 90 90]);
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


%% Now plot the full image and the scaled cropped image            
for ii = 1:size(whichLuminaceForMosaic,2)
    for jj = 1:size(whichReflectancesForMosaic,2)
        
        % Get the path corresponding to the luminance level and reflectance
        namePattern = FormatRecipeName(luminanceLevels(whichLuminaceForMosaic(ii)),...
            reflectanceNumbers(whichReflectancesForMosaic(jj)), '*', '*');        
        pathToWorkingFolder = fullfile(pathToFolder,'Working');
        infoRecipe = dir(fullfile(pathToWorkingFolder,namePattern));
        pathtoRecipe = fullfile(pathToWorkingFolder,infoRecipe.name,'ConeResponse.mat');
        imageData   = load(pathtoRecipe);
        croppedImage = imageData.recipe.processing.croppedImage;
        [sRGBCropped, ~, ~, ~] = rtbMultispectralToSRGB(croppedImage,[400,10,31],...
            'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);

        first=axes(hFig2,'units','pixels','position', ...
            [(jj-1)*95+525 (ii-1)*115+300 90 90]);
        image(uint8(sRGBCropped));
        xlabel(num2str(reflectanceNumbers(whichReflectancesForMosaic(jj))));
        axis square;
        set(gca,'xtick',[],'ytick',[]);
        if (jj == 1)
            ylabel(str2double(sprintf('%.2f',luminanceLevels(whichLuminaceForMosaic(ii)))));
        end
        
        % Get the Full image
        pathtoFullImage = fullfile(pathToWorkingFolder,infoRecipe.name,'renderings/Mitsuba/normal.mat');
        FullImageData   = load(pathtoFullImage);
        [sRGBFull, ~, ~, ~] = rtbMultispectralToSRGB(FullImageData.multispectralImage,[400,10,31],...
            'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);

        first=axes(hFig2,'units','pixels','position', ...
            [(jj-1)*165+50 (ii-1)*125+650 150 100]);
        image(uint8(sRGBFull));
        xlabel(num2str(reflectanceNumbers(whichReflectancesForMosaic(jj))));
        set(gca,'xtick',[],'ytick',[]);
        if (jj == 1)
            ylabel(str2double(sprintf('%.2f',luminanceLevels(whichLuminaceForMosaic(ii)))));
        end
        
    end
end

figFullMontage = fullfile(pathToFolder,'FullMontage.pdf');
set(gcf,'PaperPositionMode','auto');
save2pdf(figFullMontage);
close;

