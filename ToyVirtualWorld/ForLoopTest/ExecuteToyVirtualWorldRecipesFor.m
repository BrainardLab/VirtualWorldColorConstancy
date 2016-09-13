function ExecuteToyVirtualWorldRecipes(varargin)
%% Locate, unpack, and execute many WardLand recipes created earlier.
%
% Use this script to render many archived recipes created earlier.
%

%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('imageWidth', 320, @isnumeric);
parser.addParameter('imageHeight', 240, @isnumeric);
parser.addParameter('luminanceLevels', [], @isnumeric);
parser.addParameter('reflectanceNumbers', [], @isnumeric);
parser.parse(varargin{:});
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;
imageWidth = parser.Results.imageWidth;
imageHeight = parser.Results.imageHeight;

%% Overall Setup.

% location of packed-up recipes
% where to save new recipes
projectName = 'ToyVirtualWorld';
recipeFolder = fullfile(getpref(projectName, 'recipesFolder'),'Originals');
if ~exist(recipeFolder, 'dir')
    disp(['Recipe folder not found: ' recipeFolder]);
end

% location of renderings
renderingFolder = fullfile(getpref(projectName, 'recipesFolder'),'Rendered');

% edit some batch renderer options
hints.renderer = 'Mitsuba';
hints.workingFolder = getpref(projectName, 'workingFolder');
hints.imageWidth = imageWidth;
hints.imageHeight = imageHeight;

%% Locate and render packed-up recipes.
archiveFiles = FindToyVirtualWorldRecipes(recipeFolder, luminanceLevels, reflectanceNumbers);
nScenes = numel(archiveFiles);

timer = tic();
for ii = 1:nScenes
    recipe = [];
    try
        % get the recipe
        recipe = rtbUnpackRecipe(archiveFiles{ii}, 'hints', hints);
        
        % modify rendering options
        recipe.input.hints.renderer = hints.renderer;
        recipe.input.hints.workingFolder = hints.workingFolder;
        recipe.input.hints.imageWidth = hints.imageWidth;
        recipe.input.hints.imageHeight = hints.imageHeight;
        
        % render
        recipe = rtbExecuteRecipe(recipe, 'throwException', true);
        
        % save the results in a separate folder
        [archivePath, archiveBase, archiveExt] = fileparts(archiveFiles{ii});
        renderedArchiveFile = fullfile(renderingFolder, [archiveBase archiveExt]);
        excludeFolders = {'temp'};
        rtbPackUpRecipe(recipe, renderedArchiveFile, 'ignoreFolders', excludeFolders);
        
    catch err
        SaveToyVirutalWorldError(renderingFolder, err, recipe, varargin);
    end
end

toc(timer);
