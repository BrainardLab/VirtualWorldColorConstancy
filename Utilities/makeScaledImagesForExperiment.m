function makeScaledImagesForExperiment(outputName, nStimuli)
%
% makeScaledImagesForExperiment(pathToFolder,luminanceLevels,reflectanceNumbers,RecipeName)
%
% This function makes the images required for the psychophysics experiment.
% We first find a common scale factor for the three images that will be 
% presented at a time. This scale factor is used to produce the three sRGB 
% images to be displayed on the screen. We also generate the individual 
% sRGB images and the unscaled sRGB image. 
%
% The three images that will be displayed have the same scale. The scale
% changes for every stimuli.
%
% outputName: Name of parent fodler where the multispectral images.
% nStimuli: Total number of stimuli stored in the parent folder.

%% Basic setup we don't want to expose as parameters.
projectName = 'VirtualWorldColorConstancy';
hints.renderer = 'Mitsuba';
hints.isPlot = false;

pathToFolder = fullfile(getpref(projectName, 'baseFolder'),outputName);
lightnessLevelFile = fullfile(getpref(projectName, 'baseFolder'),outputName,'lightnessLevels.mat');
lightness = load(lightnessLevelFile);

%%
toneMapFactor = 0;

for sceneIndex = 1:nStimuli
    scaleFactor = 1;
    
    recipeName = ['Stimuli-',num2str(sceneIndex)];
    pathToWorkingFolder = fullfile(pathToFolder,'Working');
    
    pathToStandardFile = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','standard.mat');
    standardRadiance = parload(pathToStandardFile);
    [sRGBstandardImage, ~, ~, standardFactor] = rtbMultispectralToSRGB(standardRadiance, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'isScale',true);
    
    pathToComparision1File = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','comparision1.mat');
    Comparision1File = parload(pathToComparision1File);
    [sRGBComparision1Image, ~, ~, comparision1Factor] = rtbMultispectralToSRGB(Comparision1File, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'isScale',true);
    
    pathToComparision2File = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','comparision2.mat');
    Comparision2File = parload(pathToComparision2File);
    [sRGBComparision2Image, ~, ~, comparision2Factor] = rtbMultispectralToSRGB(Comparision2File, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'isScale',true);
    
    tempScaleFactor = min([standardFactor comparision1Factor comparision2Factor]);
    if tempScaleFactor < scaleFactor
        scaleFactor = tempScaleFactor;
    end
    
    %% Plot the unscaled figures while we are in this loop
    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 440], 'Visible', 'off');
    
    standard = axes(hFig,'units','pixels','position',[180 240 240 160]);
    image(standard,uint8(sRGBstandardImage));
    set(gca,'xtick',[],'ytick',[]);
    
    comparision1 = axes(hFig,'units','pixels','position',[40 40 240 160]);
    image(comparision1,uint8(sRGBComparision1Image));
    set(gca,'xtick',[],'ytick',[]);
    
    comparision2 = axes(hFig,'units','pixels','position',[320 40 240 160]);
    image(comparision2,uint8(sRGBComparision2Image));
    set(gca,'xtick',[],'ytick',[]);

    unscaledImages = fullfile(pathToWorkingFolder,...
        recipeName,'images','unscaledStimuli.pdf');
    set(gcf,'PaperPositionMode','auto');    
    save2pdf(unscaledImages);
    xlabel(standard,num2str(lightness.standardLightness(sceneIndex),'%.4f'));
    xlabel(comparision1,num2str(lightness.comparisionLightness1(sceneIndex),'%.4f'));
    xlabel(comparision2,num2str(lightness.comparisionLightness2(sceneIndex),'%.4f'));
    unscaledImagesWithLabels = fullfile(pathToWorkingFolder,...
        recipeName,'images','unscaledStimuliWithLabels.pdf');
    save2pdf(unscaledImagesWithLabels);
    close;

    recipeName = ['Stimuli-',num2str(sceneIndex)];
    pathToWorkingFolder = fullfile(pathToFolder,'Working');
    
    pathToStandardFile = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','standard.mat');
    standardRadiance = parload(pathToStandardFile);
    [sRGBstandardImage, ~, ~, ~] = rtbMultispectralToSRGB(standardRadiance, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);
    
    pathToComparision1File = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','comparision1.mat');
    Comparision1File = parload(pathToComparision1File);
    [sRGBComparision1Image, ~, ~, ~] = rtbMultispectralToSRGB(Comparision1File, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);
    
    pathToComparision2File = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','comparision2.mat');
    Comparision2File = parload(pathToComparision2File);
    [sRGBComparision2Image, ~, ~, ~] = rtbMultispectralToSRGB(Comparision2File, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);
    
%% Save the individual scaled iamges and the scaled stimuli for experiment
    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 440], 'Visible', 'off');
    
    standard = axes(hFig,'units','pixels','position',[180 240 240 160]);
    image(standard,uint8(sRGBstandardImage));
    set(gca,'xtick',[],'ytick',[]);
    
    comparision1 = axes(hFig,'units','pixels','position',[40 40 240 160]);
    image(comparision1,uint8(sRGBComparision1Image));
    set(gca,'xtick',[],'ytick',[]);
    
    comparision2 = axes(hFig,'units','pixels','position',[320 40 240 160]);
    image(comparision2,uint8(sRGBComparision2Image));
    set(gca,'xtick',[],'ytick',[]);

    scaledStimuli = fullfile(pathToWorkingFolder,...
        recipeName,'images','scaledStimuli.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(scaledStimuli);

    xlabel(standard,num2str(lightness.standardLightness(sceneIndex),'%.4f'));
    xlabel(comparision1,num2str(lightness.comparisionLightness1(sceneIndex),'%.4f'));
    xlabel(comparision2,num2str(lightness.comparisionLightness2(sceneIndex),'%.4f'));
    scaledImagesWithLabels = fullfile(pathToWorkingFolder,...
        recipeName,'images','scaledStimuliWithLabels.pdf');
    save2pdf(scaledImagesWithLabels);

    close;
        
    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400], 'Visible', 'off');
    image(uint8(sRGBstandardImage));
    set(gca,'xtick',[],'ytick',[]);
    standardImage = fullfile(pathToWorkingFolder,...
        recipeName,'images','standardImage.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(standardImage);
    close;

    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400], 'Visible', 'off');
    image(uint8(sRGBComparision1Image));
    set(gca,'xtick',[],'ytick',[]);
    comparision1Image = fullfile(pathToWorkingFolder,...
        recipeName,'images','comparision1Image.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(comparision1Image);
    close;

    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400], 'Visible', 'off');
    image(uint8(sRGBComparision2Image));
    set(gca,'xtick',[],'ytick',[]);
    comparision2Image = fullfile(pathToWorkingFolder,...
        recipeName,'images','comparision2Image.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(comparision2Image);
    close;
end