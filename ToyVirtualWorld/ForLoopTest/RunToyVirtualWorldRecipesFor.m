function RunToyVirtualWorldRecipesFor(varargin)
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

%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('makeWidth', 320, @isnumeric);
parser.addParameter('makeHeight', 240, @isnumeric);
parser.addParameter('makeCropImageHalfSize', 25, @isnumeric);
parser.addParameter('executeWidth', 320, @isnumeric);
parser.addParameter('executeHeight', 240, @isnumeric);
parser.addParameter('analyzeWidth', 320, @isnumeric);
parser.addParameter('analyzeHeight', 240, @isnumeric);
parser.addParameter('analyzeCropImageHalfSize', 25, @isnumeric);
parser.addParameter('luminanceLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', [1 2], @isnumeric);
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

%% Set up ful-sized parpool if available.
if exist('parpool', 'file')
    nCores = feature('numCores');
    parpool('local', nCores);
end

%% Go through the steps for this combination of parameters.
MakeToyRecipesByCombinationsFor( ...
    'imageWidth', makeWidth, ...
    'imageHeight', makeHeight, ...
    'luminanceLevels', luminanceLevels, ...
    'reflectanceNumbers', reflectanceNumbers, ...
    'cropImageHalfSize', makeCropImageHalfSize);

ExecuteToyVirtualWorldRecipesFor( ...
    'imageWidth', executeWidth, ...
    'imageHeight', executeHeight, ...
    'luminanceLevels', luminanceLevels, ...
    'reflectanceNumbers', reflectanceNumbers);

AnalyzeToyVirtualWorldRecipesFor( ...
    'imageWidth', analyzeWidth, ...
    'imageHeight', analyzeHeight, ...
    'luminanceLevels', luminanceLevels, ...
    'reflectanceNumbers', reflectanceNumbers, ...
    'cropImageHalfSize', analyzeCropImageHalfSize);

ConeResponseToyVirtualWorldRecipesFor(...
    'luminanceLevels', luminanceLevels, ...
    'reflectanceNumbers', reflectanceNumbers, ...
    'nAnnularRegions', 25);

PlotToyVirutalWorldTiming();
