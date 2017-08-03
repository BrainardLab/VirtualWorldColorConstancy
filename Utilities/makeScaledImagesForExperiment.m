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
    %% Make image with display max scaling
    scaleFactor = 1;
    
    recipeName = ['Stimuli-',num2str(sceneIndex)];
    pathToWorkingFolder = fullfile(pathToFolder,'Working');
    
    pathToStandardFile = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','standard.mat');
    standardRadiance = parload(pathToStandardFile);
    [sRGBstandardDisplayMax, ~, ~, standardFactor] = rtbMultispectralToSRGB(standardRadiance, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'isScale',true);
    
    pathToComparision1File = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','comparision1.mat');
    Comparision1File = parload(pathToComparision1File);
    [sRGBComparision1DisplayMax, ~, ~, comparision1Factor] = rtbMultispectralToSRGB(Comparision1File, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'isScale',true);
    
    pathToComparision2File = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','comparision2.mat');
    Comparision2File = parload(pathToComparision2File);
    [sRGBComparision2DisplayMax, ~, ~, comparision2Factor] = rtbMultispectralToSRGB(Comparision2File, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'isScale',true);
    
    tempScaleFactor = min([standardFactor comparision1Factor comparision2Factor]);
    if tempScaleFactor < scaleFactor
        scaleFactor = tempScaleFactor;
    end
    
    sRGBDisplayMaxScalingImages = fullfile(pathToWorkingFolder,...
        recipeName,'images','displayMaxScaling.mat');
    save(sRGBDisplayMaxScalingImages,'sRGBstandardDisplayMax','sRGBComparision1DisplayMax','sRGBComparision2DisplayMax');
    %% Plot the unscaled stimuli, standard on top, two comparisons on bottom
    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 440], 'Visible', 'off');
    
    standard = axes(hFig,'units','pixels','position',[180 240 240 160]);
    image(standard,uint8(sRGBstandardDisplayMax));
    set(gca,'xtick',[],'ytick',[]);
    
    comparision1 = axes(hFig,'units','pixels','position',[40 40 240 160]);
    image(comparision1,uint8(sRGBComparision1DisplayMax));
    set(gca,'xtick',[],'ytick',[]);
    
    comparision2 = axes(hFig,'units','pixels','position',[320 40 240 160]);
    image(comparision2,uint8(sRGBComparision2DisplayMax));
    set(gca,'xtick',[],'ytick',[]);

    stimuliDisplayMaxScaling = fullfile(pathToWorkingFolder,...
        recipeName,'images','stimuliDisplayMaxScaling.pdf');
    set(gcf,'PaperPositionMode','auto');    
    save2pdf(stimuliDisplayMaxScaling);
    xlabel(standard,num2str(lightness.standardLightness(sceneIndex),'%.4f'));
    xlabel(comparision1,num2str(lightness.comparisionLightness1(sceneIndex),'%.4f'));
    xlabel(comparision2,num2str(lightness.comparisionLightness2(sceneIndex),'%.4f'));
    stimuliDisplayMaxScalingWithLabels = fullfile(pathToWorkingFolder,...
        recipeName,'images','stimuliDisplayMaxScalingWithLabels.pdf');
    save2pdf(stimuliDisplayMaxScalingWithLabels);
    close;
    
    %% Plot the unscaled standard and comparison side by side
    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 240], 'Visible', 'off');
    
    standard = axes(hFig,'units','pixels','position',[40 40 240 160]);
    image(standard,uint8(sRGBstandardDisplayMax));
    set(gca,'xtick',[],'ytick',[]);
    
    comparision1 = axes(hFig,'units','pixels','position',[320 40 240 160]);
    image(comparision1,uint8(sRGBComparision1DisplayMax));
    set(gca,'xtick',[],'ytick',[]);
    
    stimuliSideBySideDisplayMax = fullfile(pathToWorkingFolder,...
        recipeName,'images','stimuliSideBySideDisplayMax.pdf');
    set(gcf,'PaperPositionMode','auto');    
    save2pdf(stimuliSideBySideDisplayMax);
    xlabel(standard,num2str(lightness.standardLightness(sceneIndex),'%.4f'));
    xlabel(comparision1,num2str(lightness.comparisionLightness1(sceneIndex),'%.4f'));
    stimuliSideBySideDisplayMaxWithLabels = fullfile(pathToWorkingFolder,...
        recipeName,'images','stimuliSideBySideDisplayMaxWithLabels.pdf');
    save2pdf(stimuliSideBySideDisplayMaxWithLabels);
    close;

    %% save the individual unscaled images
    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400], 'Visible', 'off');
    image(uint8(sRGBstandardDisplayMax));
    set(gca,'xtick',[],'ytick',[]);
    standardDisplayMax = fullfile(pathToWorkingFolder,...
        recipeName,'images','standardDisplayMax.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(standardDisplayMax);
    close;

    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400], 'Visible', 'off');
    image(uint8(sRGBComparision1DisplayMax));
    set(gca,'xtick',[],'ytick',[]);
    comparision1DisplayMax = fullfile(pathToWorkingFolder,...
        recipeName,'images','comparision1DisplayMax.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(comparision1DisplayMax);
    close;

    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400], 'Visible', 'off');
    image(uint8(sRGBComparision2DisplayMax));
    set(gca,'xtick',[],'ytick',[]);
    comparision2DisplayMax = fullfile(pathToWorkingFolder,...
        recipeName,'images','comparision2DisplayMax.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(comparision2DisplayMax);
    close;

    %% make sRGB images with common scaling
    [sRGBstandardCommonScale, ~, ~, ~] = rtbMultispectralToSRGB(standardRadiance, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);
    
    [sRGBComparision1CommonScale, ~, ~, ~] = rtbMultispectralToSRGB(Comparision1File, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);
    
    [sRGBComparision2CommonScale, ~, ~, ~] = rtbMultispectralToSRGB(Comparision2File, ...
        [400,10,31], 'toneMapFactor',toneMapFactor, 'scaleFactor', scaleFactor);
    
    sRGBCommonScalingImages = fullfile(pathToWorkingFolder,...
        recipeName,'images','commonScaling.mat');
    save(sRGBCommonScalingImages,'sRGBstandardCommonScale','sRGBComparision1CommonScale','sRGBComparision2CommonScale');
%% Save stimuli with common scale, standard on top, two comparision on bottom side by side
    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 440], 'Visible', 'off');
    
    standard = axes(hFig,'units','pixels','position',[180 240 240 160]);
    image(standard,uint8(sRGBstandardCommonScale));
    set(gca,'xtick',[],'ytick',[]);
    
    comparision1 = axes(hFig,'units','pixels','position',[40 40 240 160]);
    image(comparision1,uint8(sRGBComparision1CommonScale));
    set(gca,'xtick',[],'ytick',[]);
    
    comparision2 = axes(hFig,'units','pixels','position',[320 40 240 160]);
    image(comparision2,uint8(sRGBComparision2CommonScale));
    set(gca,'xtick',[],'ytick',[]);

    stimuliCommonScale = fullfile(pathToWorkingFolder,...
        recipeName,'images','stimuliCommonScale.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(stimuliCommonScale);

    xlabel(standard,num2str(lightness.standardLightness(sceneIndex),'%.4f'));
    xlabel(comparision1,num2str(lightness.comparisionLightness1(sceneIndex),'%.4f'));
    xlabel(comparision2,num2str(lightness.comparisionLightness2(sceneIndex),'%.4f'));
    stimuliCommonScaleWithLabels = fullfile(pathToWorkingFolder,...
        recipeName,'images','stimuliCommonScaleWithLabels.pdf');
    save2pdf(stimuliCommonScaleWithLabels);

    close;
        
    %% Save individual common scaled images
    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400], 'Visible', 'off');
    image(uint8(sRGBstandardCommonScale));
    set(gca,'xtick',[],'ytick',[]);
    standardCommonScale = fullfile(pathToWorkingFolder,...
        recipeName,'images','standardCommonScale.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(standardCommonScale);
    close;

    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400], 'Visible', 'off');
    image(uint8(sRGBComparision1DisplayMax));
    set(gca,'xtick',[],'ytick',[]);
    comparision1CommonScale = fullfile(pathToWorkingFolder,...
        recipeName,'images','comparision1CommonScale.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(comparision1CommonScale);
    close;

    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400], 'Visible', 'off');
    image(uint8(sRGBComparision2DisplayMax));
    set(gca,'xtick',[],'ytick',[]);
    comparision2CommonScale = fullfile(pathToWorkingFolder,...
        recipeName,'images','comparision2CommonScale.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(comparision2CommonScale);
    close;
end