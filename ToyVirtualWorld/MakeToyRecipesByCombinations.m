%% Construct and archive a set of many Ward Land recipes.
%
% The idea here is to generate many WardLand scenes.  We choose values for
% several parameter sets and build a scene for several combinations of
% values, taken from each set.
%
% Here are the parameter set's we're working with:
%
% reflectanceSet -- select several reflectances.  For each of these,
% we want to generate on the order of 100 scenes.  The generated scenes
% will be named after this reflectance.  The "center" object of the scene
% will use this reflectance.
%
% shapeSet -- select several 3D models which can be inserted into slots.
% The models are identified by name and correspond to files located in
%   VirtualScenes/ModelRepository/Objects
%
% objectSlotSet -- chooses some "slots" where we can insert objects into
% the scene.  The first slot is for the "center" object which gets the
% fixedReflectance.  The remaining slots are for other objects.  Here are
% the parameters that make up a slot:
%	position, relative to scene bounding boxes
%	rotation
%	scale
%
% baseSceneSet -- select several 3D models which make up most of the scene
% geometry and camera.  The models are identified by name and correspond to
% files located in
%   VirtualScenes/ModelRepository/BaseScenes
%
% lightSet -- choose some light sources to insert into the scene.  Here are
% the parameters tha make up a light:
%   one of the 3D models in VirtualScenes/ModelRepository/Objects
%	position, relative to scene bounding boxes
%	rotation
%	scale
%	material
%	emitted spectrum
%
% Here's how we combine all these sets to make each scene:
%   - iterate the baseSceneSet, one at a time
%   - iterate the lightSet, one at a time
%   - iterate the reflectanceSet, one at a time
%   - iterate the shapeSet, one at a time
%   - apply the chosen reflectance and shape to the "center" object in the
%   first object slot
%   - fill the remaining object slots by shuffling the remaining
%   reflectances and shapes.  Do this a small, fixed number of times (don't
%   be exhaustive with the shuffling permutations).  Call this nShuffles.
%   - pack all this up as a scene
%
% From this outline, we can figure out how many scenes we'll get:
%   nScenes = ...
%       nFixedReflectances * nShapes * nShuffles * nBaseScenes * nLights;
%
% The number of object slots doesn't affect the number of total scenes
% because we use all of the object slots every time.
%
% The number of reflectances and shapes must be at least as great as the
% number of object slots.
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
[matteMacbeth, wardMacbeth] = GetWardLandMaterials(hints);

% CIE-LAB tempterature-correlated daylight spectra
lowTemp = 4000;
highTemp = 12000;
nSpectra = 20;
temps = round(linspace(lowTemp, highTemp, nSpectra));
lightSpectra = cell(1, nSpectra);
for bb = 1:nSpectra
    lightSpectra(bb) = GetWardLandIlluminantSpectra( ...
        temps(bb), ...
        0, ...
        [lowTemp highTemp], ...
        1, ...
        hints);
end

% remember where these raw materials are so we can copy them, below
commonResourceFolder = GetWorkingFolder('resources', false, hints);

%% Choose our reflectances.

% WardLand expects reflectances in matt-ward pairs.
matteReflectanceSet = cat(2, matteTextured(1:2), matteMacbeth(1:2));
wardReflectanceSet = cat(2, wardTextured(1:2), wardMacbeth(1:2));

% give a name to each reflectance, useful for naming the output scenes
reflectanceNameSet = {'textured-1', 'textured-2', 'macbeth-1', 'macbeth-2'};

%% Which shapes do we want to insert into slots?
shapeSet = { ...
    'BigBall', ...
    'SmallBall', ...
    'RingToy', ...
    'Barrel'};

%% Where are our object slots?
objectSlotSet(1).boxPosition = [0.5 0.5 0.5];
objectSlotSet(1).rotation = [45 60 0];
objectSlotSet(1).scale = 1.5;

objectSlotSet(2).boxPosition = [0.75 0.1 0.25];
objectSlotSet(2).rotation = [45 0 45];
objectSlotSet(2).scale = .9;

objectSlotSet(3).boxPosition = [1 1 1];
objectSlotSet(3).rotation = [0 0 0];
objectSlotSet(3).scale = 1;

objectSlotSet(4).boxPosition = [0 0 0];
objectSlotSet(4).rotation = [0 16 60];
objectSlotSet(4).scale = .5;

%% Which base scenes do we want?
baseSceneSet = { ...
    'CheckerBoard', ...
    'IndoorPlant', ...
    'Library', ...
    'TableChairs'};

%% Which reflective objects do we want to insert?
lightSet(1).name = 'BigBall';
lightSet(1).boxPosition = [0.5 0.5 0.5];
lightSet(1).rotation = [0 0 0];
lightSet(1).scale = 1.5;
lightSet(1).matteMaterial = matteMacbeth{4};
lightSet(1).wardMaterial = wardMacbeth{4};
lightSet(1).lightSpectrum = lightSpectra{1};

lightSet(2).name = 'SmallBall';
lightSet(2).boxPosition = [0.5 0.5 0.5];
lightSet(2).rotation = [0 0 0];
lightSet(2).scale = .8;
lightSet(2).matteMaterial = matteMacbeth{4};
lightSet(2).wardMaterial = wardMacbeth{4};
lightSet(2).lightSpectrum = lightSpectra{1};

lightSet(3).name = 'BigBall';
lightSet(3).boxPosition = [0.25 0.75 0.25];
lightSet(3).rotation = [0 0 0];
lightSet(3).scale = 1.5;
lightSet(3).matteMaterial = matteMacbeth{4};
lightSet(3).wardMaterial = wardMacbeth{4};
lightSet(3).lightSpectrum = lightSpectra{end};

lightSet(4).name = 'SmallBall';
lightSet(4).boxPosition = [0.25 0.75 0.25];
lightSet(4).rotation = [0 0 0];
lightSet(4).scale = .8;
lightSet(4).matteMaterial = matteMacbeth{4};
lightSet(4).wardMaterial = wardMacbeth{4};
lightSet(4).lightSpectrum = lightSpectra{end};

%% How many scenes are we making?
nShuffles = 2;

nReflectances = numel(reflectanceNameSet);
nShapes = numel(shapeSet);
nSlots = numel(objectSlotSet);
nBaseScenes = numel(baseSceneSet);
nLights = numel(lightSet);

nScenes = ...
    nReflectances * nShapes * nShuffles * nBaseScenes * nLights;
fprintf('Generating %d scenes (%d x %d reflectances)\n', ...
    nScenes, nScenes / nReflectances, nReflectances);

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
% We have 6 loops here.  Sorry about the "pyramid of doom" caused by all
% the indenting!
%
for bb = 1:nBaseScenes
    % first loop chooses a base scene
    choices.baseSceneName = baseSceneSet{bb};
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
        
        for rr = 1:nReflectances
            % third loop chooses one "fixed" reflectance
            fixedMatte = matteReflectanceSet{rr};
            fixedWard = wardReflectanceSet{rr};
            fixedName = reflectanceNameSet{rr};
            
            % what reflectances are left?
            otherReflecactances = find(rr ~= 1:nReflectances);
            
            for ss = 1:nShapes
                % fourth loop chooses one shape for the "center" object
                shapeName = shapeSet{ss};
                
                % what shapes are left?
                otherShapes = find(ss ~= 1:nShapes);
                
                for ff = 1:nShuffles
                    % fifth loop shuffles the remaining reflectances and
                    % shapes and deals them into the remaining slots
                    reflectanceShuffle = otherReflecactances(randperm(nReflectances - 1));
                    reflectanceInds = [rr reflectanceShuffle];
                    shapeShuffle = otherShapes(randperm(nShapes - 1));
                    shapeInds = [ss otherShapes];
                    
                    % format our selections as a WardLand "choices" struct
                    choices.insertedObjects.names = shapeSet(shapeInds);
                    choices.insertedObjects.rotations = {objectSlotSet.rotation};
                    choices.insertedObjects.scales =  {objectSlotSet.scale};
                    choices.insertedObjects.matteMaterialSets = matteReflectanceSet(reflectanceInds);
                    choices.insertedObjects.wardMaterialSets = wardReflectanceSet(reflectanceInds);
                    choices.insertedObjects.positions = cell(1, nSlots);
                    for oo = 1:nSlots
                        % "box position" -> xyz in chosen base scene
                        slot = objectSlotSet(oo);
                        choices.insertedObjects.positions{oo} = ...
                            GetDonutPosition([0 0; 0 0; 0 0], sceneData.objectBox, slot.boxPosition);
                    end
                    
                    % scene name is like "FIXED_REFLECTANCE-on-CENTER_SHAPE-in-BASE_SCENE"
                    hints.recipeName = sprintf('%s-on-%s-in-%s', ...
                        reflectanceNameSet{rr}, shapeSet{ss}, baseSceneSet{bb});
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
        end
    end
end
