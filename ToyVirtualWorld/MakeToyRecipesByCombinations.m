%% Construct and archive a set of many Ward Land recipes.
%
% The idea here is to specify up front values for several parameter sets.
% Each parameter set contains possibilities for things like "which object
% do we insert?", "which material do we use", or "where do we insert the
% object?".
%
% Then we can iterate all the parameter sets using lots of nested loops and
% construct all the unique sets of parameter values.  I'll call one such
% set of parameter a "leaf".
%
% We could build one scene for each leaf.  In this case each scene would
% have just one inserted object.  We could also build scenes that contain
% multiple inserted objects.  Then the question is how many and which
% leaves go into each scene?
%
% I think what we discussed is for each scene to have one leaf from each
% object.  This would be a very large space to explore.  For example, say
% we obtained 8 leaves each for objects a, b, and c.  From that raw
% material we could create 16^3 = 4096 scenes!  And that is only for 3
% objects and a low estimate of the number of leaves per scene.
%
% I am wondering if this is really what we want.  Or, is there some other
% way to explore the scene space that would be more practival?
%
% BSH

%% Overall configuration.
clear;
clc;

% batch renderer options
hints.renderer = 'Mitsuba';
hints.workingFolder = getpref('VirtualScenes', 'workingFolder');
hints.isPlot = false;

defaultMappings = fullfile( ...
    VirtualScenesRoot(), 'MiscellaneousData', 'DefaultMappings.txt');

% virutal scenes options for inserted objects
scaleMin = 0.25;
scaleMax = 2.0;

% where to save new recipes
projectName = 'ToyVirtualWorld';
recipeFolder = fullfile(getpref(projectName, 'recipesFolder'),'Originals');
if (~exist(recipeFolder, 'dir'))
    mkdir(recipeFolder);
end

%% Choose various "raw materials" we will use in creating scenes.

% textured materials in matte and ward flavors
[textureIds, textures, matteTextured, wardTextured, textureFiles] = ...
    GetWardLandTextureMaterials([], hints);

% Macbeth color checker materials in matte and ward flavors
[matteMacbeth, wardMacbeth] = GetWardLandMaterials(hints);

% CIE-LAB tempterature correlated daylight spectra
lowTemp = 4000;
highTemp = 12000;
nSpectra = 20;
temps = round(linspace(lowTemp, highTemp, nSpectra));
lightSpectra = cell(1, nSpectra);
for ss = 1:nSpectra
    lightSpectra(ss) = GetWardLandIlluminantSpectra( ...
        temps(ss), ...
        0, ...
        [lowTemp highTemp], ...
        1, ...
        hints);
end

% remember where these raw materials are so we can copy them, below
commonResourceFolder = GetWorkingFolder('resources', false, hints);

%% Which base scenes do we want?
%   This parameter set chooses some scenes found in
%   VirtualScenes/ModelRepository/BaseScenes
baseSceneSet = { ...
    'CheckerBoard', ...
    'IndoorPlant', ...
    };

%% Which reflective objects do we want to insert?
%   This parameter set chooses some objects found in
%   VirtualScenes/ModelRepository/Objects
%   And for each one, assigns:
%       position, relative to scene bounding boxes
%       rotation
%       scale
%       material
%       emitted spectrum

lightSet(1).name = 'BigBall';
lightSet(1).boxPosition = [0.5 0.5 0.5];
lightSet(1).rotation = [45 60 0];
lightSet(1).scale = 1.5;
lightSet(1).matteMaterial = matteMacbeth{1};
lightSet(1).wardMaterial = wardMacbeth{1};
lightSet(1).lightSpectrum = lightSpectra{1};

%% Which reflective objects do we want to insert?
%   This parameter set chooses some objects found in
%   VirtualScenes/ModelRepository/Objects
%   And for each one, assigns:
%       position, relative to scene bounding boxes
%       rotation
%       scale
%       material

objectSet(1).name = 'Barrel';
objectSet(1).boxPosition = [0.5 0.5 0.5];
objectSet(1).rotation = [45 60 0];
objectSet(1).scale = 1.5;
objectSet(1).matteMaterial = matteMacbeth{1};
objectSet(1).wardMaterial = wardMacbeth{1};

%% Run through various combinations of scenes and lights.
%   The goal of this section is to produce several WardLand scene recipes.
%   First we make some "choices" about what will go in the scene.
%   Then we use BuildWardLandRecipe to convert the choices to a recipe.
%   Finally, we save each recipe to the recipeFolder defined above.
%
% 	The "choices" for each recipe are a struct, like this:
%               baseSceneName: 'Warehouse'
%     baseSceneMatteMaterials: {1x44 cell}
%      baseSceneWardMaterials: {1x44 cell}
%             baseSceneLights: {[1x1 struct]  [1x1 struct]}
%             insertedObjects: [1x1 struct]
%              insertedLights: [1x1 struct]
%
%   The file name for each recipe will descripe the choices somewhat.  For
%   a full account of what went into the scene, please consult the choices
%   struct.  This will be saved in the recipe as resipe.inputs.choices.

nScenes = numel(baseSceneSet);
nLights = numel(lightSet);
nObjects = numel(objectSet);
for ss = 1:nScenes
    % first loop chooses a base scene
    choices.baseSceneName = baseSceneSet{ss};
    sceneData = ReadMetadata(choices.baseSceneName);
    
    % assign arbitrary but constant materials for the base scene itself
    nBaseMaterials = numel(sceneData.materialIds);
    whichMaterials = 1 + mod((1:nBaseMaterials)-1, numel(matteMacbeth));
    choices.baseSceneMatteMaterials = matteMacbeth(whichMaterials);
    choices.baseSceneWardMaterials = wardMacbeth(whichMaterials);
    
    % assign arbitrary but constant light spectra for the base scene itself
    nBaseLights = numel(sceneData.lightIds);
    whichLights = 1 + mod((1:nBaseLights)-1, numel(lightSpectra));
    choices.baseSceneLights = lightSpectra(whichLights);
    
    for ll = 1:nLights
        % second loop chooses one light to insert into the scene
        light = lightSet(ll);
        
        % convert the abstract "box positoin" into a concrete xyz
        % within the chosen base scene
        lightPosition = GetDonutPosition( ...
            sceneData.lightExcludeBox, sceneData.lightBox, light.boxPosition);
        
        % pack up the light in the format expected for Ward Land
        choices.insertedLights.names = {light.name};
        choices.insertedLights.positions = {lightPosition};
        choices.insertedLights.rotations = {light.rotation};
        choices.insertedLights.scales = {light.scale};
        choices.insertedLights.matteMaterialSets = {light.matteMaterial};
        choices.insertedLights.wardMaterialSets = {light.wardMaterial};
        choices.insertedLights.lightSpectra = {light.lightSpectrum};
        
        % pack up the objects in the format expected for Ward Land
        objectNames = {objectSet.name};
        objectRotations = {objectSet.rotation};
        objectScales = {objectSet.scale};
        objectMattes = {objectSet.matteMaterial};
        objectWards = {objectSet.wardMaterial};
        objectPositions = {1, nObjects};
        for oo = 1:nObjects
            % third loop converts each object's abstact "box positoin"
            % into a concrete xyz within the chosen base scene
            object = objectSet(oo);
            objectPositions{oo} = GetDonutPosition( ...
                [0 0; 0 0; 0 0], sceneData.objectBox, object.boxPosition);
        end
        choices.insertedObjects.names = objectNames;
        choices.insertedObjects.positions = objectPositions;
        choices.insertedObjects.rotations = objectRotations;
        choices.insertedObjects.scales = objectScales;
        choices.insertedObjects.matteMaterialSets = objectMattes;
        choices.insertedObjects.wardMaterialSets = objectWards;
        
        % assemble the recipe
        hints.recipeName = sprintf('%s-light-%d', choices.baseSceneName, ll);
        recipe = BuildWardLandRecipe( ...
            defaultMappings, choices, textureIds, textures, hints);
        
        % remember the recipe choices
        recipe.input.choices = choices;
        
        % copy common resources into this recipe folder
        recipeResourceFolder = GetWorkingFolder('resources', false, hints);
        copyfile(commonResourceFolder, recipeResourceFolder, 'f');
        
        % save the recipe to the recipesFolder
        archiveFile = fullfile(recipeFolder, hints.recipeName);
        excludeFolders = {'scenes', 'renderings', 'images', 'temp'};
        PackUpRecipe(recipe, archiveFile, excludeFolders);
    end
end
