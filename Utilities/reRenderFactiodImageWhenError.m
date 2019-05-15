function reRenderFactiodImageWhenError(pathToErrorStruct)
%reRenderFactiodImageWhenError(pathToErrorStruct)
%
% This function re renders the factiod image struct when an error occurs
% in the makeMultispectralReflectanceImage function. The cause of this
% is not clear, as rendering the second time has always produced the
% factoids and corresponding mat files. As a fix to this bug, a
% re-rendering step is being introduced.
%
% Input: 
%   pathToErrorStruct: This is the path to the error struct. This error 
%   file is saved in a folder named Errors in the Originals folder.
% 
% Output:
%   None
%
% May 15 2019: Vijay Singh wrote this

%%

% load the .mat error file
errorFile = load(pathToErrorStruct);

% make factoids
workingRecord.recipe = errorFile.recipe;
workingRecord.hints = errorFile.recipe.input.hints;
nativeSceneFiles = fullfile(workingRecord.hints.workingFolder, ...
    workingRecord.hints.recipeName, 'scenes','Mitsuba','normal.xml');
factoidSceneFile = rtbWriteMitsubaFactoidScene(nativeSceneFiles, ...
    'hints', workingRecord.hints);
factoids = rtbRenderMitsubaFactoids(factoidSceneFile, ...
    'hints', workingRecord.hints);

% Get the reflectance image
pathToRecipeFolder = fullfile(workingRecord.hints.workingFolder,errorFile.recipeName);
reflectanceImage = makeMultispectralReflectanceImage(pathToRecipeFolder, factoids);
factoids.reflectanceImage = reflectanceImage;

% Save the multispectral and shading image in the factoids too
pathToFactoidImage = fullfile(workingRecord.hints.workingFolder, ...
    workingRecord.hints.recipeName,'renderings','Mitsuba', 'normal.mat');
normalStruct = load(pathToFactoidImage);
factoids.multispectralImage = normalStruct.multispectralImage;
factoids.shadingImage = factoids.multispectralImage./factoids.reflectanceImage;

% Save the factoid image
tempName=matfile(fullfile(workingRecord.hints.workingFolder,workingRecord.hints.recipeName, ...
    'renderings','Mitsuba','normal-factoids.mat'),'Writable',true);
tempName.factoids=factoids;

% save the recipe to the recipesFolder
originalFolder = fullfile(fileparts(workingRecord.hints.workingFolder),'Originals');
archiveFile = fullfile(originalFolder, workingRecord.hints.recipeName);
excludeFolders = {'scenes', 'renderings', 'images'};
workingRecord.recipe.input.sceneRecord = workingRecord;
workingRecord.recipe.input.hints.whichConditions = [];
rtbPackUpRecipe(workingRecord.recipe, archiveFile, 'ignoreFolders', excludeFolders);
