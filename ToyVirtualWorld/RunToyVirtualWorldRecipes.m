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

%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('luminanceLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', [1 2], @isnumeric);
parser.parse(varargin{:});
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;

%% Go through the steps for this combination of parameters.
MakeToyRecipesByCombinations( ...
    'luminanceLevels', luminanceLevels, ...
    'reflectanceNumbers', reflectanceNumbers);

ExecuteToyVirtualWorldRecipes( ...
    'luminanceLevels', luminanceLevels, ...
    'reflectanceNumbers', reflectanceNumbers);

AnalyzeToyVirtualWorldRecipes( ...
    'luminanceLevels', luminanceLevels, ...
    'reflectanceNumbers', reflectanceNumbers);
