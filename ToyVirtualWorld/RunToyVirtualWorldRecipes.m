function RunToyVirtualWorldRecipes(varargin)
% function RunToyVirtualWorldRecipes(varargin)
% 
%
% Make, Execute, and Analyze Toy Virtual World Recipes.
%
% The idea of this function is to take a parameter set and carry it through
% the all the steps of the ToyVirtualWorld project: recipe generation,
% recipe execution and rendering, and recipe analysis.
%
% This should let us divide up work in terms of what functions we pass to
% this function.  We could pass these from the command line.  That means we
% have a way to divide up work without editing our Matlab scripts.
%
% Key/value pairs
%   'outputName' - Output File Name, Default ExampleOutput
%   'imageWidth'  - MakeToyRecipesByCombinations width, Should be kept
%                  small to keep redering time low for rejected recipes
%   'imageHeight'  - MakeToyRecipesByCombinations height, Should be kept
%                  small to keep redering time low for rejected recipes
%   'cropImageHalfSize'  - crop size for MakeToyRecipesByCombinations
%   'nOtherObjectSurfaceReflectance' - Number of spectra to be generated
%                   for choosing background surface reflectance (max 999)
%   'luminanceLevels' - Luminance levels of target object
%   'reflectanceNumbers' - A row vetor containing Reflectance Numbers of 
%                   target object. These are just dummy variables to give a
%                   unique name to each random spectra.
%   'nInsertedLights' - Number of inserted lights
%   'nInsertObjects' - Number of inserted objects (other than target object)
%   'maxAttempts' - maximum number of attempts to find the right recipe
%   'targetPixelThresholdMin' - minimum fraction of target pixels that
%                 should be present in the cropped image.
%   'targetPixelThresholdMax' - maximum fraction of target pixels that
%                 should be present in the cropped image.
%   'otherObjectReflectanceRandom' - boolean to specify if spectra of 
%                   background objects is random or not. Default true
%   'illuminantSpectraRandom' - boolean to specify if spectra of 
%                   illuminant is random or not. Default true
%   'illuminantSpectrumNotFlat' - boolean to specify illumination spectra 
%                   shape to be not flat, i.e. random, (true= random)
%   'minMeanIlluminantLevel' - Min of mean value of ilumination spectrum
%   'maxMeanIlluminantLevel' - Max of mean value of ilumination spectrum
%   'targetSpectrumNotFlat' - boolean to specify arget spectra 
%                   shape to be not flat, i.e. random, (true= random)
%   'allTargetSpectrumSameShape' - boolean to specify all target spectrum 
%                   to be of same shape
%   'targetReflectanceScaledCopies' - boolean to specify target reflectance
%                   shape to be same at each reflectance number. This will
%                   create multiple hue, but the same hue will be repeated
%                   at each luminance level
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
%   'targetRotationRandom' - boolean to specify target angular position is 
%                   fixed or not. Default is true. False will only work for 
%                   Mill-Ringtoy case.
%   'baseSceneSet'  - Base scenes to be used for renderings. One of these
%                  base scenes is used for each rendering
%   'objectShapeSet'  - Shapes of the target object other inserted objects
%   'lightShapeSet'  - Shapes of the inserted illuminants
%   'mosaicHalfSize' - Cone mosaic half size
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
parser.addParameter('luminanceLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', [1 2], @isnumeric);
parser.addParameter('nInsertedLights', 1, @isnumeric);
parser.addParameter('nInsertObjects', 0, @isnumeric);
parser.addParameter('maxAttempts', 30, @isnumeric);
parser.addParameter('targetPixelThresholdMin', 0.1, @isnumeric);
parser.addParameter('targetPixelThresholdMax', 0.6, @isnumeric);
parser.addParameter('otherObjectReflectanceRandom', true, @islogical);
parser.addParameter('illuminantSpectraRandom', true, @islogical);
parser.addParameter('illuminantSpectrumNotFlat', true, @islogical);
parser.addParameter('minMeanIlluminantLevel', 10, @isnumeric);
parser.addParameter('maxMeanIlluminantLevel', 30, @isnumeric);
parser.addParameter('targetSpectrumNotFlat', true, @islogical);
parser.addParameter('allTargetSpectrumSameShape', false, @islogical);
parser.addParameter('targetReflectanceScaledCopies', false, @islogical);
parser.addParameter('lightPositionRandom', true, @islogical);
parser.addParameter('lightScaleRandom', true, @islogical);
parser.addParameter('targetPositionRandom', true, @islogical);
parser.addParameter('targetScaleRandom', true, @islogical);
parser.addParameter('targetRotationRandom', true, @islogical);
parser.addParameter('objectShapeSet', ...
    {'Barrel', 'BigBall', 'ChampagneBottle', 'RingToy', 'SmallBall', 'Xylophone'}, @iscellstr);
parser.addParameter('lightShapeSet', ...
    {'Barrel', 'BigBall', 'ChampagneBottle', 'RingToy', 'SmallBall', 'Xylophone'}, @iscellstr);
parser.addParameter('baseSceneSet', ...
    {'CheckerBoard', 'IndoorPlant', 'Library', 'Mill', 'TableChairs', 'Warehouse'}, @iscellstr);
parser.addParameter('mosaicHalfSize', 25, @isnumeric);
parser.addParameter('nRandomRotations', 0, @isnumeric);

parser.parse(varargin{:});
imageWidth = parser.Results.imageWidth;
imageHeight = parser.Results.imageHeight;
cropImageHalfSize = parser.Results.cropImageHalfSize;
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;
mosaicHalfSize = parser.Results.mosaicHalfSize;
saveRecipesConditionsTogether(parser);

%% Set up ful-sized parpool if available.
if exist('parpool', 'file')
    delete(gcp('nocreate'));
    nCores = feature('numCores');
    parpool('local', nCores);
end

%% Go through the steps for this combination of parameters.
try
    % using one base scene and one object at a time
    MakeToyRecipesByCombinations( ...
        'outputName',parser.Results.outputName,...
        'imageWidth', imageWidth, ...
        'imageHeight', imageHeight, ...
        'cropImageHalfSize', cropImageHalfSize, ...   
        'nOtherObjectSurfaceReflectance', parser.Results.nOtherObjectSurfaceReflectance,...
        'luminanceLevels', luminanceLevels, ...
        'reflectanceNumbers', reflectanceNumbers,...
        'nInsertedLights',parser.Results.nInsertedLights,...
        'nInsertObjects',parser.Results.nInsertObjects, ...
        'maxAttempts',parser.Results.maxAttempts,...
        'targetPixelThresholdMin',parser.Results.targetPixelThresholdMin, ...
        'targetPixelThresholdMax',parser.Results.targetPixelThresholdMax, ...
        'otherObjectReflectanceRandom',parser.Results.otherObjectReflectanceRandom,...
        'illuminantSpectraRandom',parser.Results.illuminantSpectraRandom,...
        'illuminantSpectrumNotFlat',parser.Results.illuminantSpectrumNotFlat,...
        'minMeanIlluminantLevel', parser.Results.minMeanIlluminantLevel,...
        'maxMeanIlluminantLevel', parser.Results.maxMeanIlluminantLevel,...
        'targetSpectrumNotFlat',parser.Results.targetSpectrumNotFlat,...
        'allTargetSpectrumSameShape',parser.Results.allTargetSpectrumSameShape,...
        'targetReflectanceScaledCopies',parser.Results.targetReflectanceScaledCopies,...
        'lightPositionRandom',parser.Results.lightPositionRandom,...
        'lightScaleRandom',parser.Results.lightScaleRandom,...
        'targetPositionRandom',parser.Results.targetPositionRandom,...
        'targetScaleRandom',parser.Results.targetScaleRandom,...
        'targetRotationRandom',parser.Results.targetRotationRandom,...
        'objectShapeSet', parser.Results.objectShapeSet, ...
        'lightShapeSet', parser.Results.lightShapeSet, ...
        'baseSceneSet', parser.Results.baseSceneSet);
        
    ConeResponseToyVirtualWorldRecipes(...
        'outputName',parser.Results.outputName,...
        'luminanceLevels', luminanceLevels, ...
        'reflectanceNumbers', reflectanceNumbers, ...
        'nAnnularRegions', 25, ...
        'mosaicHalfSize', mosaicHalfSize,...
        'cropImageHalfSize',cropImageHalfSize,...
        'nRandomRotations',parser.Results.nRandomRotations);
    
catch err
    workingFolder = fullfile(getpref('VirtualWorldColorConstancy', 'baseFolder'),parser.Results.outputName);
    SaveToyVirutalWorldError(workingFolder, err, 'RunToyVirtualWorldRecipes', varargin);
end


%% Save timing info.
PlotToyVirutalWorldTiming('outputName',parser.Results.outputName);
% Save summary of conditions in text file
saveRecipeConditionsInTextFile(parser);
