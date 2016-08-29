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

%% Choose illuminant spectra from the Illuminants folder.
lightSpectra = getIlluminantSpectra(hints);
nLightSpectra = numel(lightSpectra);

nOtherObjectSurfaceReflectance = 10000;

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
nLuminanceLevels =2;
luminanceLevels = logspace(log10(0.2),log10(0.6),nLuminanceLevels);
nReflectances = 2;
maxAttempts = 30;

targetPixelThresholdMin = 0.1;
targetPixelThresholdMax = 0.6;

% keep track of scenes generated for each condition

nScenes = nLuminanceLevels * nReflectances;
sceneRecord = struct( ...
    'targetLuminanceLevel', [], ...
    'reflectanceNumber', [],  ...
    'nAttempts', cell(1, nScenes), ...
    'choices', [], ...
    'hints', hints, ...
    'rejected', []);

% pre-fill luminance and reflectance conditions per scene
% so that we can unroll the nested loops below
for ll = 1:nLuminanceLevels
    targetLuminanceLevel = luminanceLevels(ll);
    for rr = 1:nReflectances
        sceneIndex = rr + (ll-1)*nReflectances;
        sceneRecord(sceneIndex).targetLuminanceLevel = targetLuminanceLevel;
        sceneRecord(sceneIndex).reflectanceNumber = rr;
    end
end

% iterate scene records with one parfor loop
% Matlab does not support nested parfor loops
parfor sceneIndex = 1:nScenes
    workingRecord = sceneRecord(sceneIndex);
    targetLuminanceLevel = workingRecord.targetLuminanceLevel;
    rr = workingRecord.reflectanceNumber;
    
    for attempt = 1:maxAttempts
        
        %% Pick the base scene randomly.
        bIndex = randi(size(baseSceneSet, 2), 1);
        workingRecord.choices.baseSceneName = baseSceneSet{bIndex};
        sceneData = ReadMetadata(workingRecord.choices.baseSceneName);
        
        %% Pick the target object randomly.
        targetShapeIndex = randi(nShapes, 1);
        targetShapeName = shapeSet{targetShapeIndex};
        
        %% Choose a unique name for this recipe.
        recipeName = sprintf('luminance-%0.4f-reflectance-%03d-%s-%s', ...
            targetLuminanceLevel, ...
            rr, ...
            targetShapeName, ...
            workingRecord.choices.baseSceneName);
        recipeName('.' == recipeName) = '_';
        workingRecord.hints.recipeName = recipeName;
        
        
        %% Assign a random reflectance to each object in the base scene.
        nBaseMaterials = numel(sceneData.materialIds);
        workingRecord.choices.baseSceneMatteMaterials = cell(1, nBaseMaterials);
        workingRecord.choices.baseSceneWardMaterials = cell(1, nBaseMaterials);
        pwd
        for mm = 1:nBaseMaterials
            [~, ~, ~, matteMaterial, wardMaterial] = computeLuminance( ...
                randi(nOtherObjectSurfaceReflectance), [], workingRecord.hints);
            workingRecord.choices.baseSceneMatteMaterials{mm} = matteMaterial;
            workingRecord.choices.baseSceneWardMaterials{mm} = wardMaterial;
        end
        
        %% Assign a random illuminant to each light in the base scene.
        nBaseLights = numel(sceneData.lightIds);
        whichLights = randi(nLightSpectra, [1, nBaseLights]);
        workingRecord.choices.baseSceneLights = lightSpectra(whichLights);
        
        %% Pick a light shape to insert.
        %   pack up the light in the format expected for Ward Land
        workingRecord.choices.insertedLights.names = shapeSet(randi(nShapes, 1));
        workingRecord.choices.insertedLights.positions = ...
            {GetRandomPosition(sceneData.lightExcludeBox, sceneData.lightBox)};
        workingRecord.choices.insertedLights.rotations = {randi([0, 359], [1, 3])};
        workingRecord.choices.insertedLights.scales = {.5 + rand()};
        workingRecord.choices.insertedLights.matteMaterialSets = {matteIlluminant};
        workingRecord.choices.insertedLights.wardMaterialSets = {wardIlluminant};
        workingRecord.choices.insertedLights.lightSpectra = lightSpectra(randi(nLightSpectra));
        
        %% Pick a target object and random number of "others" to insert.
        %   the "target" object is always number 1.
        nOtherObjects = 0;%1 + randi(5);
        nObjects = 1 + nOtherObjects;
        otherShapeIndices = randi(nShapes, [1 nOtherObjects]);
        
        % pack up the objects in the format expected for Ward Land
        workingRecord.choices.insertedObjects.names = cat(2, {targetShapeName}, shapeSet(otherShapeIndices));
        workingRecord.choices.insertedObjects.positions = cell(1, nObjects);
        workingRecord.choices.insertedObjects.rotations = cell(1, nObjects);
        workingRecord.choices.insertedObjects.scales = cell(1, nObjects);
        workingRecord.choices.insertedObjects.matteMaterialSets = cell(1, nObjects);
        workingRecord.choices.insertedObjects.wardMaterialSets = cell(1, nObjects);
        for oo = 1:nObjects
            % object pose in scene
            workingRecord.choices.insertedObjects.positions{oo} = GetRandomPosition([0 0; 0 0; 0 0], sceneData.objectBox);
            workingRecord.choices.insertedObjects.rotations{oo} = randi([0, 359], [1, 3]);
            workingRecord.choices.insertedObjects.scales{oo} = .5 + rand();
            
            % object reflectance
            [~, ~, ~, matteMaterial, wardMaterial] = computeLuminance( ...
                randi(nOtherObjectSurfaceReflectance), [], workingRecord.hints);
            workingRecord.choices.insertedObjects.matteMaterialSets{oo} = matteMaterial;
            workingRecord.choices.insertedObjects.wardMaterialSets{oo} = wardMaterial;
        end
        
        %% Choose a standard, numbered reflectance for the target object.
        %   and scale it based on the target luminance
        %   this writes a spectrum file to the working "resources" folder
        %   so we need to pass in the hints and hints.recipeName
        
        reflectanceFileName = sprintf('luminance-%.4f-reflectance-%03d.spd', ...
            targetLuminanceLevel, rr);
        
        [~, ~, ~, targetMatteMaterial, targetWardMaterial] = computeLuminanceByName( ...
             reflectanceFileName, workingRecord.hints);
        
        % force the target object to use this computed reflectance
        workingRecord.choices.insertedObjects.scales{1} = 1 + rand();
        workingRecord.choices.insertedObjects.matteMaterialSets{1} = targetMatteMaterial;
        workingRecord.choices.insertedObjects.wardMaterialSets{1} = targetWardMaterial;
        
        %% Position the camera.
        %   "eye" position is from the first camera "slot"
        %   "target" position is the target object's position
        %   "up" direction is from the first camera "slot"
        eye = sceneData.cameraSlots(1).position;
        target = workingRecord.choices.insertedObjects.positions{1};
        up = sceneData.cameraSlots(1).up;
        lookAt = sprintf('%f %f %f ', eye, target, up);
        
        %% Build the recipe.
        recipe = BuildToyRecipe( ...
            defaultMappings, workingRecord.choices, {}, {}, lookAt, workingRecord.hints);
        
        % copy common resources into this recipe folder
        recipeResourceFolder = GetWorkingFolder('resources', false, workingRecord.hints);
        copyfile(commonResourceFolder, recipeResourceFolder, 'f');
        
        %% Do a mask rendering, reject if target object is occluded.
        rejected = CheckTargetObjectOcclusion(recipe, ...
            'targetPixelThresholdMin', targetPixelThresholdMin, ...
            'targetPixelThresholdMax', targetPixelThresholdMax, ...
            'totalBoundingBoxPixels', 2601); % 2601 = 51* 51
        if rejected
            % delete this recipe and try again
            rejectedFolder = GetWorkingFolder('', false, workingRecord.hints);
            [status, result] = rmdir(rejectedFolder, 's');
            continue;
        else
            % move on to save this recipe
            break;
        end
    end
    
    % keep track of attempts and rejections
    workingRecord.nAttempts = attempt;
    workingRecord.rejected = rejected;
    
    if rejected
        warning('%s rejected after %d attempts!', ...
            workingRecord.hints.recipeName, attempt);
    else
        fprintf('%s accepted after %d attempts.\n', ...
            workingRecord.hints.recipeName, attempt);
        
        % save the recipe to the recipesFolder
        archiveFile = fullfile(originalFolder, workingRecord.hints.recipeName);
        excludeFolders = {'scenes', 'renderings', 'images', 'temp'};
        recipe.input.sceneRecord = workingRecord;
        recipe.input.hints.whichConditions = [];
        rtbPackUpRecipe(recipe, archiveFile, 'ignoreFolders', excludeFolders);
    end
    
    sceneRecord(sceneIndex) = workingRecord;
    
%     error('stop after one for testing')
end
