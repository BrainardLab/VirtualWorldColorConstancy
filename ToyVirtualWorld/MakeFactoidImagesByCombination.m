function MakeFactoidImagesByCombination(varargin)
%% Locate, unpack, and execute many WardLand recipes created earlier.
%
% Use this script to get cone responses.
%
%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('outputName','ExampleOutput',@ischar);
parser.addParameter('luminanceLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', [1 2], @isnumeric);
parser.parse(varargin{:});
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;

%% Overall Setup.

% location of packed-up recipes
projectName = 'VirtualWorldColorConstancy';
recipeFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName, 'Originals');
if ~exist(recipeFolder, 'dir')
    disp(['Recipe folder not found: ' recipeFolder]);
end

% edit some batch renderer options
hints.renderer = 'Mitsuba';
hints.workingFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Working');

%% Analyze each packed up recipe.
archiveFiles = FindToyVirtualWorldRecipes(recipeFolder, luminanceLevels, reflectanceNumbers);
nRecipes = numel(archiveFiles);

parfor ii = 1:nRecipes
    workingRecord = [];
    try
        % get the recipe
        recipe = rtbUnpackRecipe(archiveFiles{ii}, 'hints', hints);
        rtbChangeToWorkingFolder('hints', recipe.input.hints);
        
        workingRecord.recipe = recipe;
        workingRecord.hints = recipe.input.hints;
        % Get the factoid images
        nativeSceneFiles = fullfile(workingRecord.hints.workingFolder, ...
            workingRecord.hints.recipeName, 'scenes','Mitsuba','normal.xml');
        factoidSceneFile = rtbWriteMitsubaFactoidScene(nativeSceneFiles, ...
            'hints', workingRecord.hints);
        factoids = rtbRenderMitsubaFactoids(factoidSceneFile, ...
            'hints', workingRecord.hints);
        
        % Get the reflectance image
        pathToRecipeFolder = fullfile(workingRecord.hints.workingFolder,workingRecord.hints.recipeName);
        reflectanceImage = makeMultispectralReflectanceImage(pathToRecipeFolder, factoids);
        factoids.reflectanceImage = reflectanceImage;
        
        % Save the multispectral and shading image in the factoids too
        pathToFactoidImage = fullfile(workingRecord.hints.workingFolder, ...
            workingRecord.hints.recipeName, 'renderings','Mitsuba','normal.mat');
        normalStruct = load(pathToFactoidImage);
        factoids.multispectralImage = normalStruct.multispectralImage;
        factoids.shadingImage = factoids.multispectralImage./factoids.reflectanceImage;
        
        % Save the factoid image
        tempName=matfile(fullfile(workingRecord.hints.workingFolder,workingRecord.hints.recipeName, ...
            'renderings','Mitsuba','normal-factoids.mat'),'Writable',true);
        tempName.factoids=factoids;
        
    end
end