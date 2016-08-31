function AnalyzeToyVirtualWorldRecipes(varargin)
%% Locate, unpack, and execute many WardLand recipes created earlier.
%
% Use this script to analyze many archived recipes rendered earlier.
%

%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('luminanceLevels', [], @isnumeric);
parser.addParameter('reflectanceNumbers', [], @isnumeric);
parser.parse(varargin{:});
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;

%% Overall Setup.

% location of packed-up recipes
projectName = 'ToyVirtualWorld';
recipeFolder = fullfile(getpref(projectName, 'recipesFolder'), 'Rendered');
if ~exist(recipeFolder, 'dir')
    disp(['Recipe folder not found: ' recipeFolder]);
end

% location of saved figures
figureFolder = fullfile(getpref(projectName, 'recipesFolder'), 'Figures');

% location of analysed folder
analysedFolder = fullfile(getpref(projectName, 'recipesFolder'),'Analysed');

% edit some batch renderer options
hints.renderer = 'Mitsuba';
hints.workingFolder = getpref(projectName, 'workingFolder');

% analysis params
toneMapFactor = 10;
isScale = true;
filterWidth = 7;
lmsSensitivities = 'T_cones_ss2';

% easier to read plots
set(0, 'DefaultAxesFontSize', 14)

cropImageHalfSize = 25;

%% Analyze each packed up recipe.
archiveFiles = FindToyVirtualWorldRecipes(recipeFolder, luminanceLevels, reflectanceNumbers);
nRecipes = numel(archiveFiles);

parfor ii = 1:nRecipes
    recipe = [];
    try
        % get the recipe
        recipe = rtbUnpackRecipe(archiveFiles{ii}, 'hints', hints);
        ChangeToWorkingFolder(recipe.input.hints);
        
        % run basic recipe analysis functions
        recipe = MakeToyRGBImages(recipe, toneMapFactor, isScale);
        recipe = MakeToyAlbedoFactoidImages(recipe, toneMapFactor, isScale);
        recipe = MakeToyShapeIndexFactoidImages(recipe,cropImageHalfSize);
        
        % save the results in a separate folder
        [archivePath, archiveBase, archiveExt] = fileparts(archiveFiles{ii});
        analysedArchiveFile = fullfile(analysedFolder, [archiveBase archiveExt]);
        excludeFolders = {'temp'};
        rtbPackUpRecipe(recipe, analysedArchiveFile, 'ignoreFolders', excludeFolders);
        
    catch err
        SaveToyVirutalWorldError(analysedFolder, err, recipe, varargin);
    end
end
