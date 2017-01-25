function RunToyVirtualWorldRecipes(varargin)
% function RunToyVirtualWorldRecipes(varargin)
% 
% Example: Uses a fixed target object - Bigball, and fixed basescene -
% Library, fixed size and position of light source, fixed position and 
% scale of target object, fixed illuminant spectra, fixed background object
% reflectance spectra.
% 
% RunToyVirtualWorldRecipes('luminanceLevels',[0.2],'reflectanceNumbers',[1], ...
% 'executeWidth',320,'executeHeight', 240,'analyzeWidth',320,'analyzeHeight',240,...
% 'analyzeCropImageHalfSize', 25, 'shapeSet',{'BigBall'},'baseSceneSet',{'Library'},...
% 'otherObjectReflectanceRandom',false,'illuminantSpectraRandom',false,...
% 'lightPositionFixed',true, 'lightScaleFixed', true, 'targetPositionFixed',true,'targetScaleFixed',true)
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



% want each run to start with its own random seed
rng('shuffle');


%% Get inputs and defaults.
parser = inputParser();
parser.KeepUnmatched = true;
parser.addParameter('outputName','ExampleOutput',@ischar);
parser.addParameter('makeWidth', 320, @isnumeric);
parser.addParameter('makeHeight', 240, @isnumeric);
parser.addParameter('makeCropImageHalfSize', 25, @isnumeric);
parser.addParameter('executeWidth', 640, @isnumeric);
parser.addParameter('executeHeight', 480, @isnumeric);
parser.addParameter('analyzeWidth', 640, @isnumeric);
parser.addParameter('analyzeHeight', 480, @isnumeric);
parser.addParameter('analyzeCropImageHalfSize', 50, @isnumeric);
parser.addParameter('luminanceLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', [1 2], @isnumeric);
parser.addParameter('mosaicHalfSize', 50, @isnumeric);
parser.addParameter('otherObjectReflectanceRandom', 1, @islogical);
parser.addParameter('illuminantSpectraRandom', 1, @islogical);
parser.addParameter('lightPositionFixed', 0, @islogical);
parser.addParameter('lightScaleFixed', 0, @islogical);
parser.addParameter('targetPositionFixed', 0, @islogical);
parser.addParameter('targetScaleFixed', 0, @islogical);
parser.addParameter('shapeSet', ...
    {'Barrel', 'BigBall', 'ChampagneBottle', 'RingToy', 'SmallBall', 'Xylophone'}, @iscellstr);
parser.addParameter('baseSceneSet', ...
    {'CheckerBoard', 'IndoorPlant', 'Library', 'Mill', 'TableChairs', 'Warehouse'}, @iscellstr);

parser.parse(varargin{:});
makeWidth = parser.Results.makeWidth;
makeHeight = parser.Results.makeHeight;
makeCropImageHalfSize = parser.Results.makeCropImageHalfSize;
executeWidth = parser.Results.executeWidth;
executeHeight = parser.Results.executeHeight;
analyzeWidth = parser.Results.analyzeWidth;
analyzeHeight = parser.Results.analyzeHeight;
analyzeCropImageHalfSize = parser.Results.analyzeCropImageHalfSize;
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;
mosaicHalfSize = parser.Results.mosaicHalfSize;

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
        'shapeSet', parser.Results.shapeSet, ...
        'baseSceneSet', parser.Results.baseSceneSet, ...
        'otherObjectReflectanceRandom',parser.Results.otherObjectReflectanceRandom,...
        'illuminantSpectraRandom',parser.Results.illuminantSpectraRandom,...
        'lightPositionFixed',parser.Results.lightPositionFixed,...
        'lightScaleFixed',parser.Results.lightScaleFixed,...
        'targetPositionFixed',parser.Results.targetPositionFixed,...
        'targetScaleFixed',parser.Results.targetScaleFixed,...
        'imageWidth', makeWidth, ...
        'imageHeight', makeHeight, ...
        'luminanceLevels', luminanceLevels, ...
        'reflectanceNumbers', reflectanceNumbers, ...
        'cropImageHalfSize', makeCropImageHalfSize);
    
    ExecuteToyVirtualWorldRecipes( ...
        'outputName',parser.Results.outputName,...
        'imageWidth', executeWidth, ...
        'imageHeight', executeHeight, ...
        'luminanceLevels', luminanceLevels, ...
        'reflectanceNumbers', reflectanceNumbers);
    
    AnalyzeToyVirtualWorldRecipes( ...
        'outputName',parser.Results.outputName,...
        'imageWidth', analyzeWidth, ...
        'imageHeight', analyzeHeight, ...
        'luminanceLevels', luminanceLevels, ...
        'reflectanceNumbers', reflectanceNumbers, ...
        'cropImageHalfSize', analyzeCropImageHalfSize);
    
    ConeResponseToyVirtualWorldRecipes(...
        'outputName',parser.Results.outputName,...
        'luminanceLevels', luminanceLevels, ...
        'reflectanceNumbers', reflectanceNumbers, ...
        'nAnnularRegions', 25, ...
        'mosaicHalfSize', mosaicHalfSize);
    
catch err
    workingFolder = fullfile(getpref('VirtualWorldColorConstancy', 'baseFolder'),parser.Results.outputName);
    SaveToyVirutalWorldError(workingFolder, err, 'RunToyVirtualWorldRecipes', varargin);
end


%% Save timing info.
PlotToyVirutalWorldTiming('outputName',parser.Results.outputName);
