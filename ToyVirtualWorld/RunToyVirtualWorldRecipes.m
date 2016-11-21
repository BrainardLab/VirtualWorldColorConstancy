function RunToyVirtualWorldRecipes(varargin)
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
    shapeSet = {'BigBall'};
    baseSceneSet = {'Library'};
    MakeToyRecipesByCombinations( ...
        'shapeSet', shapeSet, ...
        'baseSceneSet', baseSceneSet, ...
        'imageWidth', makeWidth, ...
        'imageHeight', makeHeight, ...
        'luminanceLevels', luminanceLevels, ...
        'reflectanceNumbers', reflectanceNumbers, ...
        'cropImageHalfSize', makeCropImageHalfSize);
    
    ExecuteToyVirtualWorldRecipes( ...
        'imageWidth', executeWidth, ...
        'imageHeight', executeHeight, ...
        'luminanceLevels', luminanceLevels, ...
        'reflectanceNumbers', reflectanceNumbers);
    
    AnalyzeToyVirtualWorldRecipes( ...
        'imageWidth', analyzeWidth, ...
        'imageHeight', analyzeHeight, ...
        'luminanceLevels', luminanceLevels, ...
        'reflectanceNumbers', reflectanceNumbers, ...
        'cropImageHalfSize', analyzeCropImageHalfSize);
    
    ConeResponseToyVirtualWorldRecipes(...
        'luminanceLevels', luminanceLevels, ...
        'reflectanceNumbers', reflectanceNumbers, ...
        'nAnnularRegions', 25, ...
        'mosaicHalfSize', mosaicHalfSize);
    
catch err
    workingFolder = fullfile(getpref('ToyVirtualWorld', 'recipesFolder'));
    SaveToyVirutalWorldError(workingFolder, err, 'RunToyVirtualWorldRecipes', varargin);
end


%% Save timing info.
PlotToyVirutalWorldTiming();
