%% Construct and archive a set of many Ward Land recipes.
%
% The idea here is to generate many WardLand scenes.  We choose values for
% several parameter sets and build a scene for several combinations of
% parameter values, drawing from each parameter set.
%
% (The way we do this has been in flux.  So maybe we write the
% documentation after the design has settled and things are working.)
%

%% Overall configuration.
clear;
clc;

% add what we need to the path
AddToMatlabPathDynamically(fullfile(pwd,'../ToyVirtualWorld',''));
AddToMatlabPathDynamically(fullfile(pwd,'../Utilities',''));

% batch renderer options
projectName = 'ToyVirtualWorld';
hints.renderer = 'Mitsuba';
hints.workingFolder = getpref(projectName, 'workingFolder');
hints.isPlot = false;

defaultMappings = fullfile( ...
    VirtualScenesRoot(), 'MiscellaneousData', 'DefaultMappings.txt');

% where to save new recipes
originalFolder = fullfile(getpref(projectName, 'recipesFolder'), 'Originals');
if (~exist(originalFolder, 'dir'))
    mkdir(originalFolder);
end

%% Choose various CIE-LAB temperature-correlated daylight spectra.

% CIE-LAB tempterature-correlated daylight spectra
lowTemp = 4000;
highTemp = 12000;
nIlluminantSpectra = 20;
temps = round(linspace(lowTemp, highTemp, nIlluminantSpectra));
lightSpectra = cell(1, nIlluminantSpectra);
for bb = 1:nIlluminantSpectra
    lightSpectra(bb) = GetWardLandIlluminantSpectra( ...
        temps(bb), ...
        0, ...
        [lowTemp highTemp], ...
        1, ...
        hints);
end

% flat reflectance for illuminants
matteIlluminant = BuildDesription('material', 'matte', ...
    {'diffuseReflectance'}, ...
    {'300:0.5 800:0.5'}, ...
    {'spectrum'});
wardIlluminant = BuildDesription('material', 'anisoward', ...
    {'diffuseReflectance', 'specularReflectance'}, ...
    {'300:0.5 800:0.5', '300:0.1 800:0.1'}, ...
    {'spectrum', 'spectrum'});

% remember where these raw materials are so we can copy them, below
commonResourceFolder = GetWorkingFolder('resources', false, hints);

%% Which shapes do we want to insert into the scene?
shapeSet = { ...
    'Barrel', ...
    'BigBall', ...
    'ChampagneBottle', ...
    'RingToy', ...
    'SmallBall', ...
    'Xylophone'};
nShapes = numel(shapeSet);

%% Which base scenes do we want?
baseSceneSet = { ...
    'CheckerBoard', ...
    'IndoorPlant', ...
    'Library', ...
    'Mill', ...
    'TableChairs', ...
    'Warehouse'};
nBaseScenes = numel(baseSceneSet);

%% Assemble recipies by combinations of target luminances reflectances.
% The first loop runs through the target luminance levels for the standard
% day-light oberserver.
%
% The second loop runs through the reflectance levels we want to use in
% rendering.
%
% The third loop may repeat the recipe generation for the same conditions,
% in case the target object was occluded.

% luminanceLevels = [0.1:0.1:1.0];
% nReflectances = 10;
luminanceLevels = [0.1 0.5 1.0];
nReflectances = 3;
maxAttempts = 30;

targetPixelThresholdMin = 0.1;
targetPixelThresholdMax = 0.6;

% keep track of how many attempts per scene
nScenes = numel(luminanceLevels) * nReflectances;
attemptRecord = struct( ...
    'nAttempts', cell(1, nScenes), ...
    'choices', [], ...
    'rejected', []);

sceneIndex = 0;
for targetLuminanceLevel = luminanceLevels
    
    for rr = 1:nReflectances
        sceneIndex = sceneIndex + 1;
        
        for attempt = 1:maxAttempts
            
            %% Pick the base scene randomly.
            bIndex = randi(size(baseSceneSet, 2), 1);
            choices.baseSceneName = baseSceneSet{bIndex};
            sceneData = ReadMetadata(choices.baseSceneName);
            
            %% Pick the target object randomly.
            targetShapeIndex = randi(nShapes, 1);
            targetShapeName = shapeSet{targetShapeIndex};
            
            %% Choose a unique name for this recipe.
            recipeName = sprintf('luminance-%0.2f-reflectance-%03d-%s-%s', ...
                targetLuminanceLevel, ...
                rr, ...
                targetShapeName, ...
                choices.baseSceneName);
            recipeName('.' == recipeName) = '_';
            hints.recipeName = recipeName;
            
            
            %% Assign a random reflectance to each object in the base scene.
            nBaseMaterials = numel(sceneData.materialIds);
            choices.baseSceneMatteMaterials = cell(1, nBaseMaterials);
            choices.baseSceneWardMaterials = cell(1, nBaseMaterials);
            for mm = 1:nBaseMaterials
                [~, ~, ~, matteMaterial, wardMaterial] = computeLuminance( ...
                    randi(nReflectances), [], hints);
                choices.baseSceneMatteMaterials{mm} = matteMaterial;
                choices.baseSceneWardMaterials{mm} = wardMaterial;
            end
            
            %% Assign a random illuminant to each light in the base scene.
            nBaseLights = numel(sceneData.lightIds);
            whichLights = randi(nIlluminantSpectra, [1, nBaseLights]);
            choices.baseSceneLights = lightSpectra(whichLights);
            
            %% Pick a light shape to insert.
            %   pack up the light in the format expected for Ward Land
            choices.insertedLights.names = shapeSet(randi(nShapes, 1));
            choices.insertedLights.positions = ...
                {GetRandomPosition(sceneData.lightExcludeBox, sceneData.lightBox)};
            choices.insertedLights.rotations = {randi([0, 359], [1, 3])};
            choices.insertedLights.scales = {.5 + rand()};
            choices.insertedLights.matteMaterialSets = {matteIlluminant};
            choices.insertedLights.wardMaterialSets = {wardIlluminant};
            choices.insertedLights.lightSpectra = lightSpectra(randi(nIlluminantSpectra));
            
            %% Pick a target object and random number of "others" to insert.
            %   the "target" object is always number 1.
            nOtherObjects = 0;%1 + randi(5);
            nObjects = 1 + nOtherObjects;
            otherShapeIndices = randi(nShapes, [1 nOtherObjects]);
            
            % pack up the objects in the format expected for Ward Land
            choices.insertedObjects.names = cat(2, {targetShapeName}, shapeSet(otherShapeIndices));
            choices.insertedObjects.positions = cell(1, nObjects);
            choices.insertedObjects.rotations = cell(1, nObjects);
            choices.insertedObjects.scales = cell(1, nObjects);
            choices.insertedObjects.matteMaterialSets = cell(1, nObjects);
            choices.insertedObjects.wardMaterialSets = cell(1, nObjects);
            for oo = 1:nObjects
                % object pose in scene
                choices.insertedObjects.positions{oo} = GetRandomPosition([0 0; 0 0; 0 0], sceneData.objectBox);
                choices.insertedObjects.rotations{oo} = randi([0, 359], [1, 3]);
                choices.insertedObjects.scales{oo} = .5 + rand();
                
                % object reflectance
                [~, ~, ~, matteMaterial, wardMaterial] = computeLuminance( ...
                    randi(nReflectances), [], hints);
                choices.insertedObjects.matteMaterialSets{oo} = matteMaterial;
                choices.insertedObjects.wardMaterialSets{oo} = wardMaterial;
            end
            
            %% Choose a standard, numbered reflectance for the target object.
            %   and scale it based on the target luminance
            %   this writes a spectrum file to the working "resources" folder
            %   so we need to pass in the hints and hints.recipeName
            [~, ~, ~, targetMatteMaterial, targetWardMaterial] = computeLuminance( ...
                rr, targetLuminanceLevel, hints);
            
            % force the target object to use this computed reflectance
            choices.insertedObjects.scales{1} = 1 + rand();
            choices.insertedObjects.matteMaterialSets{1} = targetMatteMaterial;
            choices.insertedObjects.wardMaterialSets{1} = targetWardMaterial;
            
            %% Position the camera.
            %   "eye" position is from the first camera "slot"
            %   "target" position is the target object's position
            %   "up" direction is from the first camera "slot"
            eye = sceneData.cameraSlots(1).position;
            target = choices.insertedObjects.positions{1};
            up = sceneData.cameraSlots(1).up;
            lookAt = sprintf('%f %f %f ', eye, target, up);
            
            %% Build the recipe.
            recipe = BuildToyRecipe( ...
                defaultMappings, choices, {}, {}, lookAt, hints);
            
            % remember the recipe choices
            recipe.input.choices = choices;
            
            % copy common resources into this recipe folder
            recipeResourceFolder = GetWorkingFolder('resources', false, hints);
            copyfile(commonResourceFolder, recipeResourceFolder, 'f');
            
            %% Do a mask rendering, reject if target object is occluded.
            rejected = CheckTargetObjectOcclusion(recipe, ...
                'targetPixelThresholdMin', targetPixelThresholdMin, ...
                'targetPixelThresholdMax', targetPixelThresholdMax, ...
                'totalBoundingBoxPixels', 2601); % 2601 = 51* 51
            if rejected
                % delete this recipe and try again
                rejectedFolder = GetWorkingFolder('', false, hints);
                [status, result] = rmdir(rejectedFolder, 's');
                continue;
            else
                % move on to save this recipe
                break;
            end
        end
        
        % keep track of attempts and rejections
        attemptRecord(sceneIndex).nAttempts = attempt;
        attemptRecord(sceneIndex).choices = choices;
        attemptRecord(sceneIndex).rejected = rejected;
        
        if rejected
            warning('%s rejected after %d attempts!', ...
                hints.recipeName, attempt);
        else
            fprintf('%s accepted after %d attempts.\n', ...
                hints.recipeName, attempt);
            
            % save the recipe to the recipesFolder
            archiveFile = fullfile(originalFolder, hints.recipeName);
            excludeFolders = {'scenes', 'renderings', 'images', 'temp'};
            recipe.input.hints.whichConditions = [];
            rtbPackUpRecipe(recipe, archiveFile, 'ignoreFolders', excludeFolders);
        end
    end
end
