function RunMakeAllRecipesForStimuli(varargin)
% RunMakeAllRecipesForStimuli(varargin)
% 
%
% Run the script to make psychophysics experiment data
%
% The idea here is to specify the lightness levels of the standard and
% comparison images and produce the images that will be compared. By
% default, there the two comparison images will be identical except for the
% target object reflectance.
%
% Key/value pairs
%   'outputName' - Output File Name, Default ExampleOutput
%   'imageWidth'  - MakeToyRecipesByCombinations width, Should be kept
%                  small to keep redering time low for rejected recipes
%   'imageHeight'  - MakeToyRecipesByCombinations height, Should be kept
%                  small to keep redering time low for rejected recipes
%   'cropImageHalfSize'  - crop size for MakeToyRecipesByCombinations
%   'analyzeCropImageHalfSize' - crop image size for analysis, default is
%                    50, twice of cropImageHalfSize default
%   'standardLightness' - lightness of standard image target object
%   'comparisionLightness1' - lightness of first comparision target object
%   'comparisionLightness2' - lightness of second comparision target object
%
%   'mosaicHalfSize' - Cone mosaic half size
%   'otherObjectReflectanceRandom' - boolean to specify if spectra of 
%                   background objects is random or not. Default true
%   'illuminantSpectraRandom' - boolean to specify if spectra of 
%                   illuminant is random or not. Default true
%   'lightPositionRandom' - boolean to specify illuminant position is fixed
%                   or not. Default is true. False will only work for 
%                   library-bigball case.
%   'lightScaleRandom' - boolean to specify illuminant scale/size. Default 
%                   is true.
%   'targetPositionRandom' - boolean to specify illuminant scale/size. 
%                   Default is true. False will only work for 
%                   library-bigball case.
%   'targetScaleRandom' - boolean to specify target scale/size is fixed or 
%                   not. Default is true.
%   'baseSceneSet'  - Base scenes to be used for renderings. One of these
%                  base scenes is used for each rendering
%   'shapeSet'  - Shapes of the object that can be used for target
%                      object, illuminant and other inserted objects
%   'nRandomRotations'  - Number of random rotations applied to the
%                   rendered image to get new set of cone responses

%% Want each run to start with its own random seed
rng('shuffle');

%% Get inputs and defaults.
parser = inputParser();
parser.KeepUnmatched = true;
parser.addParameter('outputName','ExampleOutput',@ischar);
parser.addParameter('imageWidth', 320, @isnumeric);
parser.addParameter('imageHeight', 240, @isnumeric);
parser.addParameter('cropImageHalfSize', 25, @isnumeric);
parser.addParameter('nOtherObjectSurfaceReflectance', 100, @isnumeric);
parser.addParameter('standardLightness', [0.2 0.6], @isnumeric);
parser.addParameter('comparisionLightness1', [0.2 0.6], @isnumeric);
parser.addParameter('comparisionLightness2', [0.2 0.6], @isnumeric);
parser.addParameter('nInsertedLights', 1, @isnumeric);
parser.addParameter('nInsertObjects', 0, @isnumeric);
parser.addParameter('maxAttempts', 30, @isnumeric);
parser.addParameter('targetPixelThresholdMin', 0.1, @isnumeric);
parser.addParameter('targetPixelThresholdMax', 0.6, @isnumeric);
parser.addParameter('identicalStandardAndComparison', false, @islogical);
parser.addParameter('otherObjectReflectanceRandom', true, @islogical);
parser.addParameter('illuminantSpectraRandom', true, @islogical);
parser.addParameter('illuminantSpectrumNotFlat', true, @islogical);
parser.addParameter('minMeanIlluminantLevel', 10, @isnumeric);
parser.addParameter('maxMeanIlluminantLevel', 30, @isnumeric);
parser.addParameter('targetSpectrumNotFlat', true, @islogical);
parser.addParameter('targetSpectrumSameShape', false, @islogical);
parser.addParameter('lightPositionRandom', true, @islogical);
parser.addParameter('lightScaleRandom', true, @islogical);
parser.addParameter('targetPositionRandom', true, @islogical);
parser.addParameter('targetScaleRandom', true, @islogical);
parser.addParameter('shapeSet', ...
    {'Barrel', 'BigBall', 'ChampagneBottle', 'RingToy', 'SmallBall', 'Xylophone'}, @iscellstr);
parser.addParameter('baseSceneSet', ...
    {'CheckerBoard', 'IndoorPlant', 'Library', 'Mill', 'TableChairs', 'Warehouse'}, @iscellstr);
parser.addParameter('mosaicHalfSize', 25, @isnumeric);
parser.addParameter('nRandomRotations', 0, @isnumeric);

parser.parse(varargin{:});
imageWidth = parser.Results.imageWidth;
imageHeight = parser.Results.imageHeight;
cropImageHalfSize = parser.Results.cropImageHalfSize;
standardLightness = parser.Results.standardLightness;
comparisionLightness1 = parser.Results.comparisionLightness1;
comparisionLightness2 = parser.Results.comparisionLightness2;
mosaicHalfSize = parser.Results.mosaicHalfSize;
% saveRecipesConditionsTogether(parser);

%% Set up ful-sized parpool if available.
if exist('parpool', 'file')
    delete(gcp('nocreate'));
    nCores = feature('numCores');
    parpool('local', nCores);
end

%% Go through the steps for this combination of parameters.
try
    % using one base scene and one object at a time
    MakeAllRecipesForStimuli( ...
        'outputName',parser.Results.outputName,...
        'imageWidth', imageWidth, ...
        'imageHeight', imageHeight, ...
        'cropImageHalfSize', cropImageHalfSize, ...   
        'nOtherObjectSurfaceReflectance', parser.Results.nOtherObjectSurfaceReflectance,...
        'standardLightness', standardLightness, ...
        'comparisionLightness1', comparisionLightness1, ...
        'comparisionLightness2', comparisionLightness2, ...
        'nInsertedLights',parser.Results.nInsertedLights,...
        'nInsertObjects',parser.Results.nInsertObjects, ...
        'maxAttempts',parser.Results.maxAttempts,...
        'targetPixelThresholdMin',parser.Results.targetPixelThresholdMin, ...
        'targetPixelThresholdMax',parser.Results.targetPixelThresholdMax, ...
        'identicalStandardAndComparison',parser.Results.identicalStandardAndComparison,...
        'otherObjectReflectanceRandom',parser.Results.otherObjectReflectanceRandom,...
        'illuminantSpectraRandom',parser.Results.illuminantSpectraRandom,...
        'illuminantSpectrumNotFlat',parser.Results.illuminantSpectrumNotFlat,...
        'minMeanIlluminantLevel', parser.Results.minMeanIlluminantLevel,...
        'maxMeanIlluminantLevel', parser.Results.maxMeanIlluminantLevel,...
        'targetSpectrumNotFlat',parser.Results.targetSpectrumNotFlat,...
        'targetSpectrumSameShape',parser.Results.targetSpectrumSameShape,...
        'lightPositionRandom',parser.Results.lightPositionRandom,...
        'lightScaleRandom',parser.Results.lightScaleRandom,...
        'targetPositionRandom',parser.Results.targetPositionRandom,...
        'targetScaleRandom',parser.Results.targetScaleRandom,...
        'shapeSet', parser.Results.shapeSet, ...
        'baseSceneSet', parser.Results.baseSceneSet);
        
        makeScaledImagesForExperiment(parser.Results.outputName, length(standardLightness));
    
catch err
    workingFolder = fullfile(getpref('VirtualWorldColorConstancy', 'baseFolder'),parser.Results.outputName);
    SaveToyVirutalWorldError(workingFolder, err, 'RunToyVirtualWorldRecipes', varargin);
end


%% Save timing info.
% PlotToyVirutalWorldTiming('outputName',parser.Results.outputName);
% Save summary of conditions in text file
% saveRecipeConditionsInTextFile(parser);
