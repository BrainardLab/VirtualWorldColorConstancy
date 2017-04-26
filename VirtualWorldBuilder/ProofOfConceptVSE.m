%% Generate recipes as in ToyVirtualWorld, using with VirtualScenesEngine.
%
% This is BSH making a start at updating our recipe generation code to use
% RenderToolbox4 and VirtualScenesEngine, instead of the old RenderToolbox3
% code.
%
% I'm sorry I didn't have time to work this through to production.  But I
% am hoping this proof of concept will be enough so that you can see how to
% generate vwcc-style recipes using the VirtualScenesEngine, and run with
% it.  Qapla'!
%
% Ben H

clear;
clc;

%% Choose batch render options.
hints.fov = deg2rad(60);
hints.imageHeight = 480;
hints.imageWidth = 640;
hints.renderer = 'Mitsuba';
hints.recipeName = 'vwccVseProofOfConcept';

projectName = 'VirtualWorldColorConstancy';
hints.workingFolder = fullfile(getpref(projectName, 'baseFolder'), 'Working');


%% Confgigure where to find assets.
aioPrefs.locations = aioLocation( ...
    'name', 'VirtualScenesExampleAssets', ...
    'strategy', 'AioFileSystemStrategy', ...
    'baseDir', fullfile(vseaRoot(), 'examples'));


%% Choose base scenes to pick from.
baseSceneNames = {'CheckerBoard', 'IndoorPlant', 'Library', ...
    'Mill', 'TableChairs', 'Warehouse'};

% this will load models using mexximp
%   from a toolbox called VirtualScenesExampleAssets
%   which is similar to our older VirtualScenes repository
nBaseScenes = numel(baseSceneNames);
baseScenes = cell(1, nBaseScenes);
baseSceneInfos = cell(1, nBaseScenes);
for bb = 1:nBaseScenes
    name = baseSceneNames{bb};
    [baseScenes{bb}, baseSceneInfos{bb}] = VseModel.fromAsset('BaseScenes', name, ...
        'aioPrefs', aioPrefs, ...
        'nameFilter', 'blend$');
end


%% Choose shapes to insert.
shapeNames = {'Barrel', 'BigBall', 'ChampagneBottle', ...
    'RingToy', 'SmallBall', 'Xylophone'};

% this will load models, like above
nShapes = numel(shapeNames);
shapes = cell(1, nShapes);
for ss = 1:nShapes
    name = shapeNames{ss};
    shapes{ss} = VseModel.fromAsset('Objects', name, ...
        'aioPrefs', aioPrefs, ...
        'nameFilter', 'blend$');
end


%% Choose light spectra.

% Sorry this is a simple, static list.  But you could replace it with
% another cell array of spectrum strings or .spd file names.
% emitterSpectra = { ...
%     '300:2 800:0', ...
%     '300:0 800:2', ...
%     '300:1 800:1'};
% emitterBaseDir = fullfile('/Users/dhb','Desktop','TestVSEData');
emitterBaseDir = fullfile('/Users/vsin/Desktop/Data/');

emitterLocations.config.baseDir = emitterBaseDir;
emitterLocations.name = 'ToyVirtualWorldIlluminants';
emitterLocations.strategy = 'AioFileSystemStrategy';
emitterAioPrefs = aioPrefs;
emitterAioPrefs.locations = emitterLocations;
emitterSpectra = aioGetFiles('Illuminants', 'BaseScene', ...
    'aioPrefs', emitterAioPrefs, ...
    'fullPaths', false);

%% Choose reflectances for the scene overall.
%
% We created some spectra and stuck them in a directory, which 
% we point to in the variable reflectanceBaseDir.
%
% We then get those into the right format using aioGetFiles, with aioPrefs
% set to point at where our spectra are.
%
% The problem is, when it comes time to apply the style, the thing doing
% the applying doesn't know where these files are, and thus doesn't copy
% them over into the resource folder.  So they don't end up in the resource
% folder, and the rendering crashes because it can't find them we we try to
% execute the recipe.
%
% What we need is the "right" way to point at a set of spectra outside of
% the Matlab path, someplace where we generated spectra, and then to get
% them into the recipe's resource folder.
% reflectanceBaseDir = fullfile('/Users/dhb','Desktop','TestVSEData');
reflectanceBaseDir = fullfile('/Users/vsin/Desktop/Data/');
reflectanceLocations.config.baseDir = reflectanceBaseDir;
reflectanceLocations.name = 'ToyVirtualWorldReflectances';
reflectanceLocations.strategy = 'AioFileSystemStrategy';
reflectanceAioPrefs = aioPrefs;
reflectanceAioPrefs.locations = reflectanceLocations;
baseSceneReflectances = aioGetFiles('Reflectances', 'OtherObjects', ...
    'aioPrefs', reflectanceAioPrefs, ...
    'fullPaths', false);

% This was the original example version, currently commented out.
%
% Sorry this is just the color checker spectra.  But you could replace this
% list with a list of cleverly generated spectrum strings or .spd file
% names.
%
% baseSceneReflectances = aioGetFiles('Reflectances', 'ColorChecker', ...
%     'aioPrefs', aioPrefs, ...
%     'fullPaths', false);


%% Choose the specific reflectance for the target object.

% Again, sorry this is a silly, static spectrum.  But you could replace it
% with a better spectrum string or .spd file name.
% targetObjectReflectance = '300:0 800:1';

targetBaseDir = fullfile('/Users/vsin/Desktop/Data/');
targetLocations.config.baseDir = targetBaseDir;
targetLocations.name = 'ToyVirtualWorldTarget';
targetLocations.strategy = 'AioFileSystemStrategy';
targetAioPrefs = aioPrefs;
targetAioPrefs.locations = targetLocations;
targetObjectReflectance = aioGetFiles('Reflectances', 'TargetObjects', ...
    'aioPrefs', targetAioPrefs, ...
    'fullPaths', false);


%% Randomly pick a base scene and shapes to insert.
baseSceneIndex = 3;% randi(nBaseScenes);
baseSceneInfo = baseSceneInfos{baseSceneIndex};
baseScene = baseScenes{baseSceneIndex}.copy('name', 'base');

nInsertShapes = 2;
shapeIndexes = randi(nShapes, [1, nInsertShapes]);

nInsertLights = 2;
lightIndexes = randi(nShapes, [1, nInsertLights]);


%% For each shape insert, choose a random spatial transformation.
insertShapes = cell(1, nInsertShapes);
for ss = 1:nInsertShapes
    shape = shapes{shapeIndexes(ss)};
    
    rotationX = randi([0, 359]);
    rotationY = randi([0, 359]);
    rotationZ = randi([0, 359]);
    position = GetRandomPosition([0 0; 0 0; 0 0], baseSceneInfo.objectBox);
    scale = 0.3 + rand()/2;
    transformation = mexximpScale(scale) ...
        * mexximpRotate([1 0 0], rotationX) ...
        * mexximpRotate([0 1 0], rotationY) ...
        * mexximpRotate([0 0 1], rotationZ) ...
        * mexximpTranslate(position);
    
    shapeName = sprintf('shape-%02d', ss);
    insertShapes{ss} = shape.copy( ...
        'name', shapeName, ...
        'transformation', transformation);
    
    % remember the position of the first, "target" shape
    if 1 == ss
        targetPosition = position;
    end
end


%% Point the camera at the target shape.
eye = baseSceneInfo.cameraSlots(1).position;
target = targetPosition;
up = baseSceneInfo.cameraSlots(1).up;
lookAt = mexximpLookAt(eye, target, up);

cameraName = baseScene.model.cameras(1).name;
isCameraNode = strcmp(cameraName, {baseScene.model.rootNode.children.name});
baseScene.model.rootNode.children(isCameraNode).transformation = lookAt;


%% For each light insert, choose a random spatial transformation.
insertLights = cell(1, nInsertLights);
for ll = 1:nInsertLights
    light = shapes{lightIndexes(ll)};
    
    rotationX = randi([0, 359]);
    rotationY = randi([0, 359]);
    rotationZ = randi([0, 359]);
    position = GetRandomPosition(baseSceneInfo.lightExcludeBox, baseSceneInfo.lightBox);
    scale = 0.3 + rand()/2;
    transformation = mexximpScale(scale) ...
        * mexximpRotate([1 0 0], rotationX) ...
        * mexximpRotate([0 1 0], rotationY) ...
        * mexximpRotate([0 0 1], rotationZ) ...
        * mexximpTranslate(position);
    
    lightName = sprintf('light-%d', ss);
    insertLights{ll} = light.copy(...
        'name', lightName, ...
        'transformation', transformation);
end


%% Choose styles for the black and white mask rendering.

% do a low quality, direct lighting rendering
quickRendering = VwccMitsubaRenderingQuality( ...
    'integratorPluginType', 'direct', ...
    'samplerPluginType', 'ldsampler');
quickRendering.addIntegratorProperty('shadingSamples', 'integer', 32);
quickRendering.addSamplerProperty('sampleCount', 'integer', 32);

% turn all materials into black diffuse
allBlackDiffuse = VseMitsubaDiffuseMaterials( ...
    'name', 'allBlackDiffuse');
allBlackDiffuse.addSpectrum('300:0 800:0');

% make the target shape a uniform emitter
firstShapeEmitter = VseMitsubaAreaLights( ...
    'name', 'targetEmitter', ...
    'modelNameFilter', 'shape-01', ...
    'elementNameFilter', '', ...
    'elementTypeFilter', 'nodes', ...
    'defaultSpectrum', '300:1 800:1');

% these styles make up the "mask" condition
styles.mask = {quickRendering, allBlackDiffuse, firstShapeEmitter};


%% Choose styles for the full radiance rendering.

% do a higher quality, path tracing rendering
fullRendering = VwccMitsubaRenderingQuality( ...
    'integratorPluginType', 'path', ...
    'samplerPluginType', 'ldsampler');
fullRendering.addIntegratorProperty('maxDepth', 'integer', 10);
fullRendering.addSamplerProperty('sampleCount', 'integer', 512);

% bless specific meshes in the base scene as area lights
nBaseLights = numel(baseSceneInfo.lightIds);
baseLightNames = cell(1, nBaseLights);
for ll = 1:nBaseLights
    lightId = baseSceneInfo.lightIds{ll};
    meshSuffixIndex = strfind(lightId, '-mesh');
    if ~isempty(meshSuffixIndex)
        baseLightNames{ll} = lightId(1:meshSuffixIndex-1);
    else
        baseLightNames{ll} = lightId;
    end
end
baseLightFilter = sprintf('%s|', baseLightNames{:});
baseLightFilter = baseLightFilter(1:end-1);
blessBaseLights = VseMitsubaAreaLights( ...
    'name', 'blessBaseLights', ...
    'applyToInnerModels', false, ...
    'elementNameFilter', baseLightFilter);

% bless inserted light meshes as area lights
blessInsertedLights = VseMitsubaAreaLights( ...
    'name', 'blessInsertedLights', ...
    'applyToOuterModels', false, ...
    'modelNameFilter', 'light-', ...
    'elementNameFilter', '');

% assign spectra to lights
areaLightSpectra = VseMitsubaEmitterSpectra( ...
    'name', 'areaLightSpectra', ...
    'pluginType', 'area', ...
    'propertyName', 'radiance');
%areaLightSpectra.spectra = emitterSpectra;
areaLightSpectra.resourceFolder = emitterBaseDir;
areaLightSpectra.addManySpectra(emitterSpectra);

% assign spectra to materials in the base scene
%
% note setting of resourceFolder to point to where the
% files with the spectra live.  This is necessary so
% that when the recipe gets built, these spectral files
% can be found and copied into the right place.
baseSceneDiffuse = VseMitsubaDiffuseMaterials( ...
    'name', 'baseSceneDiffuse', ...
    'applyToInnerModels', false);
baseSceneDiffuse.resourceFolder = reflectanceBaseDir;
baseSceneDiffuse.addManySpectra(baseSceneReflectances);

% assign spectra to all materials of inserted shapes
insertedSpectra = aioGetFiles('Reflectances', 'OtherObjects', ...
    'aioPrefs', reflectanceAioPrefs, ...
    'fullPaths', false);
insertedDiffuse = VseMitsubaDiffuseMaterials( ...
    'name', 'insertedDiffuse', ...
    'applyToOuterModels', false);
insertedDiffuse.addManySpectra(insertedSpectra);

% assign a specific reflectance to the target object
targetDiffuse = VseMitsubaDiffuseMaterials( ...
    'name', 'targetDiffuse', ...
    'applyToOuterModels', false, ...
    'modelNameFilter', 'shape-01');
% targetDiffuse.addSpectrum(targetObjectReflectance);
targetDiffuse.resourceFolder = reflectanceBaseDir;
targetDiffuse.addManySpectra({targetObjectReflectance{1}});

styles.normal = {fullRendering, ...
    blessBaseLights, blessInsertedLights, areaLightSpectra, ...
    baseSceneDiffuse, insertedDiffuse, targetDiffuse};

%% Build recipe and render it.

% combine the models and make one condition per field of the styles struct
innerModels = [insertShapes{:} insertLights{:}];
recipe = vseBuildRecipe(baseScene, innerModels, styles, 'hints', hints);

% generate scene files and render
recipe = rtbExecuteRecipe(recipe);


%% Preview.

isScale = true;
toneMapFactor = 100;

nRenderings = numel(recipe.rendering.radianceDataFiles);
for rr = 1:nRenderings
    [~, conditionName] = fileparts(recipe.rendering.radianceDataFiles{rr});
    
    rgb = rtbMakeMontage(recipe.rendering.radianceDataFiles(rr), ...
        'isScale', isScale, ...
        'toneMapFactor', toneMapFactor, ...
        'hints', hints);
    
    figure();
    imshow(uint8(rgb));
    drawnow();
    title(conditionName);
end
