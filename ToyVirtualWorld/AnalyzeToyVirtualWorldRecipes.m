%% Locate, unpack, and execute many WardLand recipes created earlier.
%
% Use this script to analyze many archived recipes rendered earlier.
%
% You can configure a few recipe parameters at the top of this script.
%
% @ingroup WardLand

%% Overall Setup.
clear;
clc;

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
archiveFiles = FindFiles(recipeFolder, '\.zip$');
nRecipes = numel(archiveFiles);

for ii = 1:nRecipes
    % get the recipe
    recipe = UnpackRecipe(archiveFiles{ii}, hints);
    ChangeToWorkingFolder(recipe.input.hints);
    
    % run basic recipe analysis functions
    recipe = MakeToyRGBImages(recipe, toneMapFactor, isScale);
    recipe = MakeToyAlbedoFactoidImages(recipe, toneMapFactor, isScale);
    recipe = MakeToyShapeIndexFactoidImages(recipe,cropImageHalfSize);
    
        % save the results in a separate folder
    [archivePath, archiveBase, archiveExt] = fileparts(archiveFiles{ii});
    analysedArchiveFile = fullfile(analysedFolder, [archiveBase archiveExt]);
    excludeFolders = {'temp'};
    PackUpRecipe(recipe, analysedArchiveFile, excludeFolders);

end
