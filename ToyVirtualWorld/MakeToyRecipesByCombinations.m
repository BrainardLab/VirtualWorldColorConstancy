%% Construct and archive a set of many Ward Land recipes.
%
% The idea here is to generate many WardLand scenes.  We choose values for
% several parameter sets and build a scene for each combination of values.
%
% For now, there are 3 parameter sets:
% 
% baseSceneSet chooses some parent scenes located in 
%   VirtualScenes/ModelRepository/BaseScenes
%
% lightSet chooses some objects found in
%   VirtualScenes/ModelRepository/Objects
% For each one, it also assigns a:
%       position, relative to scene bounding boxes
%       rotation
%       scale
%       material
%       emitted spectrum
%
% objectSet also chooses some objects found in
%   VirtualScenes/ModelRepository/Objects
% For each one, it also assigns a:
%       position, relative to scene bounding boxes
%       rotation
%       scale
%       material
%
% We include all the objects in each scene.  So this part is constant
% across recipes.
%
% We could add more parameter sets.  For example, one natural extension
% would be to extract a materialSet, separate from the objectSet, and then
% make combinations of materials and objects.  We could do likewise for
% positions, rotations, light spectra, etc.
%
% Another extension might be to add additional object sets.  We could
% think of one set as the "fixed" objects, and the other sets as the
% "changing" objects.
%
% Potentially, we could extract lots of parameter sets.  The number of
% resulting combinations and recipes would grow geometrically.  So maybe we
% want to think about which parameter sets we care about most and focus on
% these?
%
% BSH

%% Overall configuration.
clear;
clc;

% batch renderer options
projectName = 'ToyVirtualWorld';
hints.renderer = 'Mitsuba';
hints.workingFolder = getpref(projectName, 'workingFolder');
hints.isPlot = false;

defaultMappings = fullfile( ...
    VirtualScenesRoot(), 'MiscellaneousData', 'DefaultMappings.txt');

% where to save new recipes
recipeFolder = fullfile(getpref(projectName, 'recipesFolder'),'Originals');
if (~exist(recipeFolder, 'dir'))
    mkdir(recipeFolder);
end

%% Choose various "raw materials" we will use in creating scenes.

% textured materials in matte and ward flavors
[textureIds, textures, matteTextured, wardTextured, textureFiles] = ...
    GetWardLandTextureMaterials([], hints);

% Macbeth color checker materials in m[atte and ward flavors
matteMacbeth, wardMacbeth] = GetWardLandMaterials(hints);

% CIE-LAB tempterature-correlated daylight spectra
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
lightSet(1).matteMaterial = matteMacbeth{4};
lightSet(1).wardMaterial = wardMacbeth{4};
lightSet(1).lightSpectrum = lightSpectra{1};

lightSet(2).name = 'SmallBall';
lightSet(2).boxPosition = [0.25 0.75 0.25];
lightSet(2).rotation = [0 0 10];
lightSet(2).scale = .8;
lightSet(2).matteMaterial = matteMacbeth{4};
lightSet(2).wardMaterial = wardMacbeth{4};
lightSet(2).lightSpectrum = lightSpectra{end};

% etc...

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

objectSet(2).name = 'Xylophone';
objectSet(2).boxPosition = [0.75 0.1 0.25];
objectSet(2).rotation = [45 0 45];
objectSet(2).scale = .9;
objectSet(2).matteMaterial = matteTextured{1};
objectSet(2).wardMaterial = wardTextured{1};

% etc...

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
%   The file name for each recipe will describe the choices somewhat, but
%   no completely.  For a full account of what went into the scene, please
%   consult the choices struct.  This will be saved in the recipe as
%   resipe.inputs.choices. 

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
