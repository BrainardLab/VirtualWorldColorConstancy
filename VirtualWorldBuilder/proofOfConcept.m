%% Generate recipes as in ToyVirtualWorld, using with VirtualScenesEngine.
%
% This is BSH making a start at updating our recipe generation code to use
% RenderToolbox4 and VirtualScenesEngine, instead of the old RenderToolbox3
% code.
%
% I'm sorry to say I probably won't be able to finish.  But I am hoping to
% make enough of a start that you can see how to generate vwcc-style
% recipes using the VirtualScenesEngine, and I hope that will be enough for
% you to pick up and run with.  Qapla'!
%

clear;
clc;

%% Choose batch render options.
hints.fov = deg2rad(60);
hints.imageHeight = 240;
hints.imageWidth = 320;
hints.renderer = 'Mitsuba';
hints.recipeName = 'vwccVseProofOfConcept';

projectName = 'VirtualWorldColorConstancy';
hints.workingFolder = fullfile(getpref(projectName, 'baseFolder'), 'Working');


%% Confgigure where to find assets.
aioPrefs.locations = aioLocation( ...
    'name', 'VirtualScenesExampleAssets', ...
    'strategy', 'AioFileSystemStrategy', ...
    'baseDir', fullfile(vseaRoot(), 'examples'));


%% Choose base scenes to work with.
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


%% Choose objects to insert.
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


%% Chose which base scene and which shapes and lights to insert.
baseSceneIndex = randi(nBaseScenes);
baseSceneInfo = baseSceneInfos{bb};
baseScene = baseScenes{baseSceneIndex}.copy('name', 'base');

nInsertShapes = 3;
shapeIndexes = randi(nShapes, [1, nInsertShapes]);

nInsertLights = 2;
lightIndexes = randi(nShapes, [1, nInsertLights]);


%% For each shape insert, choose a random spatial transformation.
insertShapes = cell(1, nInsertShapes);
for ss = 1:nInsertShapes
    shape = shapes{ss};
    
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
    
    shapeName = sprintf('shape-%d', ss);
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
insertLights = cell(1, nInsertShapes);
for ll = 1:nInsertLights
    light = shapes{ll};
    
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


%% Build recipe, render, and preview.
innerModels = [insertShapes{:} insertLights{:}];
styles.none = {};
recipe = vseBuildRecipe(baseScene, innerModels, styles, 'hints', hints);

recipe = rtbExecuteRecipe(recipe);

imshow(uint8(recipe.processing.srgbMontage));


%% Notes.

% full radiance rendering (a style)
% quick mask rendering (a style)
% make everything black except the target object area light (a style)

% build recipes
%   one style set is quick and make everything black
%   one style is full radiance and use "real" spectra

% luminance levels
% reflectances

% assign reflectances in base scene (a style)
% assign illuminant spectra in base scene (a style)
% assign reflectances to inserted shapes (a style)
% assign reflectance to target shape (a style)
% assign illuminant spectra in inserted lights (a style)

