function S = MakeStimuliStructForExperiment(fodlerName, nStimuli)
%
% S = makeStimuliStructForExperiment(fodlerName, nStimuli)
%
% This function makes the stimuli struct given the output folder name where
% the stimuli are stored and the total number of stimuli.
%
% fodlerName: Name of parent fodler where the multispectral images.
% nStimuli: Total number of stimuli stored in the parent folder.
% 
% S.stimuliFolder : The folder where the data is stored
% S.stdImg = standard hyperspectral image
% S.stdImgSz = size of multispectral standard image
% S.stdX = standard lightness level
% S.stdWavelength = Wavelength samples for multispectral image [start dx n]
% S.stdRadiometricScaleFactor = radiometric scale factor
%
% S.cmp1Img = comparison hyperspectral image 1
% S.cmp1ImgSz = size of multispectral comparision 1 image
% S.cmp1X = comparision lightness level 1
% S.cmp1Wavelength = Wavelength samples for multispectral image [start dx n]
% S.cmp1RadiometricScaleFactor = radiometric scale factor
%
% S.cmp2Img = comparison hyperspectral image 2
% S.cmp2ImgSz = size of multispectral comparision 2 image
% S.cmp2X = comparision lightness level 2
% S.cmp2Wavelength = Wavelength samples for multispectral image [start dx n]
% S.cmp2RadiometricScaleFactor = radiometric scale factor
%
% Aug 15, 2017, VS wrote this
%% Basic setup we don't want to expose as parameters.
projectName = 'VirtualWorldColorConstancy';
hints.renderer = 'Mitsuba';
hints.isPlot = false;

pathToFolder = fullfile(getpref(projectName, 'baseFolder'),fodlerName);
lightnessLevelFile = fullfile(getpref(projectName, 'baseFolder'),fodlerName,'lightnessLevels.mat');
lightness = load(lightnessLevelFile);

%% Define the struct and add some basic info about the file
S = struct;
S.stimuliFolder = fodlerName;


for sceneIndex = 1:nStimuli
    recipeName = ['Stimuli-',num2str(sceneIndex)];
    pathToWorkingFolder = fullfile(pathToFolder,'Working');
    
    pathToStandardFile = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','standard.mat');
    stdStruct = load(pathToStandardFile);
    standardRadiance = stdStruct.multispectralImage;
    S.stdImg(sceneIndex,:) = standardRadiance(:)';
    S.stdImgSz(sceneIndex,:) = size(standardRadiance);
    S.stdX(sceneIndex,:) = lightness.standardLightness(sceneIndex);
    S.stdWavelength(sceneIndex,:) = stdStruct.S;
    S.stdRadiometricScaleFactor(sceneIndex,:) = stdStruct.radiometricScaleFactor;
    
    pathToComparision1File = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','comparision1.mat');
    cmp1Struct = load(pathToComparision1File);
    Comparision1File = cmp1Struct.multispectralImage;
    S.cmp1Img(sceneIndex,:) = Comparision1File(:)';
    S.cmp1ImgSz(sceneIndex,:) = size(Comparision1File);
    S.cmp1X(sceneIndex,:) = lightness.comparisionLightness1(sceneIndex);
    S.cmp1Wavelength(sceneIndex,:) = cmp1Struct.S;
    S.cmp1RadiometricScaleFactor(sceneIndex,:) = cmp1Struct.radiometricScaleFactor;
    
    pathToComparision2File = fullfile(pathToWorkingFolder,...
        recipeName,'renderings','Mitsuba','comparision2.mat');
    cmp2Struct = load(pathToComparision2File);
    Comparision2File = cmp2Struct.multispectralImage;
    S.cmp2Img(sceneIndex,:) = Comparision2File(:)';
    S.cmp2ImgSz(sceneIndex,:) = size(Comparision2File);
    S.cmp2X(sceneIndex,:) = lightness.comparisionLightness2(sceneIndex);
    S.cmp2Wavelength(sceneIndex,:) = cmp2Struct.S;
    S.cmp2RadiometricScaleFactor(sceneIndex,:) = cmp2Struct.radiometricScaleFactor;    
    
end