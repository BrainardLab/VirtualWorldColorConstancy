function makeScaledImagesForExperiment(outputName, nStimuli)
%
% makeScaledImagesForExperiment(pathToFolder,luminanceLevels,reflectanceNumbers,RecipeName)
%
% This function makes the images required for the psychophysics experiment.
% We first find a common scale factor for all the stimuli and then make
% individual sRGB images for display as well as an images that has the
% standard and comparision images together. We will generate both a set of
% stimuli that has the full image and a set that has the cropped image. The
% scaling is done for the full image and the for the cropped image, the
% scaling is done for the cropped image.
%
% pathToFolder: The path to the job folder
%

%% Basic setup we don't want to expose as parameters.
projectName = 'VirtualWorldColorConstancy';
hints.renderer = 'Mitsuba';
hints.isPlot = false;

pathToFolder = fullfile(getpref(projectName, 'baseFolder'),outputName);

%%
toneMapFactor = 0;

scaleFactor = 1;

for sceneIndex = 1:nStimuli
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
    set(hFig,'units','pixels', 'Position', [1 1 600 600]);
    
    %     standard = axes(hFig,'units','pixels','position',[150 350 150 100]);
    subplot(2,2,1);
    image(uint8(sRGBstandardImage));
    set(gca,'xtick',[],'ytick',[]);
    
    %     comparision1 = axes(hFig,'units','pixels','position',[50 50 150 100]);
    subplot(2,2,3);
    image(uint8(sRGBComparision1Image));
    set(gca,'xtick',[],'ytick',[]);
    
    %     comparision2 = axes(hFig,'units','pixels','position',[350 50 150 100]);
    subplot(2,2,4);
    image(uint8(sRGBComparision2Image));
    set(gca,'xtick',[],'ytick',[]);

    unscaledImages = fullfile(pathToWorkingFolder,...
        recipeName,'images','unscaledStimuli.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(unscaledImages);
    close;
end


for sceneIndex = 1:nStimuli
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
    set(hFig,'units','pixels', 'Position', [1 1 600 600]);
    
    %     standard = axes(hFig,'units','pixels','position',[150 350 150 100]);
    subplot(2,2,1);
    image(uint8(sRGBstandardImage));
    set(gca,'xtick',[],'ytick',[]);
    
    %     comparision1 = axes(hFig,'units','pixels','position',[50 50 150 100]);
    subplot(2,2,3);
    image(uint8(sRGBComparision1Image));
    set(gca,'xtick',[],'ytick',[]);
    
    %     comparision2 = axes(hFig,'units','pixels','position',[350 50 150 100]);
    subplot(2,2,4);
    image(uint8(sRGBComparision2Image));
    set(gca,'xtick',[],'ytick',[]);

    scaledStimuli = fullfile(pathToWorkingFolder,...
        recipeName,'images','scaledStimuli.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(scaledStimuli);
    close;
        
    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400]);
    image(uint8(sRGBstandardImage));
    set(gca,'xtick',[],'ytick',[]);
    standardImage = fullfile(pathToWorkingFolder,...
        recipeName,'images','standardImage.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(standardImage);
    close;

    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400]);
    image(uint8(sRGBComparision1Image));
    set(gca,'xtick',[],'ytick',[]);
    comparision1Image = fullfile(pathToWorkingFolder,...
        recipeName,'images','comparision1Image.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(comparision1Image);
    close;

    hFig = figure();
    set(hFig,'units','pixels', 'Position', [1 1 600 400]);
    image(uint8(sRGBComparision2Image));
    set(gca,'xtick',[],'ytick',[]);
    comparision2Image = fullfile(pathToWorkingFolder,...
        recipeName,'images','comparision2Image.pdf');
    set(gcf,'PaperPositionMode','auto');
    save2pdf(comparision2Image);
    close;
end