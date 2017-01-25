function AnalyzeToyVirtualWorldRecipes(varargin)
%% Locate, unpack, and execute many WardLand recipes created earlier.
%
% Use this script to analyze many archived recipes rendered earlier.
%

%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('outputName','ExampleOutput',@ischar);
parser.addParameter('imageWidth', 320, @isnumeric);
parser.addParameter('imageHeight', 240, @isnumeric);
parser.addParameter('luminanceLevels', [], @isnumeric);
parser.addParameter('reflectanceNumbers', [], @isnumeric);
parser.addParameter('cropImageHalfSize', 25, @isnumeric);
parser.parse(varargin{:});
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;
imageWidth = parser.Results.imageWidth;
imageHeight = parser.Results.imageHeight;
cropImageHalfSize = parser.Results.cropImageHalfSize;
%% Overall Setup.

% location of packed-up recipes
projectName = 'VirtualWorldColorConstancy';
recipeFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName, 'Rendered');
if ~exist(recipeFolder, 'dir')
    disp(['Recipe folder not found: ' recipeFolder]);
end

% location of saved figures
figureFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName, 'Figures');

% location of analysed folder
analysedFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Analysed');

% edit some batch renderer options
hints.renderer = 'Mitsuba';
hints.workingFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Working');
hints.imageWidth = imageWidth;
hints.imageHeight = imageHeight;

% analysis params
toneMapFactor = 10;
isScale = true;
filterWidth = 7;
lmsSensitivities = 'T_cones_ss2';

% easier to read plots
set(0, 'DefaultAxesFontSize', 14)

%% Analyze each packed up recipe.
archiveFiles = FindToyVirtualWorldRecipes(recipeFolder, luminanceLevels, reflectanceNumbers);
nRecipes = numel(archiveFiles);

parfor ii = 1:nRecipes
    recipe = [];
    try
        % get the recipe
        recipe = rtbUnpackRecipe(archiveFiles{ii}, 'hints', hints);
        recipe.input.hints.imageWidth = hints.imageWidth;
        recipe.input.hints.imageHeight = hints.imageHeight;
        rtbChangeToWorkingFolder('hints', recipe.input.hints);
        
        % run basic recipe analysis functions
        recipe = MakeToyRGBImages(recipe, toneMapFactor, isScale);
        recipe = MakeToyAlbedoFactoidImages(recipe, toneMapFactor, isScale);
        recipe = MakeToyShapeIndexFactoidImages(recipe,cropImageHalfSize);
        
        % save the results in a separate folder
        [archivePath, archiveBase, archiveExt] = fileparts(archiveFiles{ii});
        analysedArchiveFile = fullfile(analysedFolder, [archiveBase archiveExt]);
        excludeFolders = {'temp', 'resources', 'scenes'};
        rtbPackUpRecipe(recipe, analysedArchiveFile, 'ignoreFolders', excludeFolders);
        
        % clean up temp files we don't need going forward
        tempFolder = rtbWorkingFolder('folderName', 'temp', 'hints', recipe.input.hints);
        if exist(tempFolder, 'dir')
            rmdir(tempFolder, 's');
        end
        
    catch err
        SaveToyVirutalWorldError(analysedFolder, err, recipe, varargin);
    end
end
