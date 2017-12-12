function MakeToyRecipesByCombinations(varargin)
%% Construct and archive a set of many Ward Land recipes.
%
% The idea here is to generate many WardLand scenes.  We choose values for
% several parameter sets and build a scene for several combinations of
% parameter values, drawing from each parameter set.
%
% Key/value pairs
%   'outputName' - Output File Name, Default ExampleOutput
%   'imageWidth' - image width, Should be kept small to keep redering time
%                   low for rejected recipes
%   'imageHeight'- image height, Should be kept small to keep redering time
%                   low for rejected recipes
%   'makeCropImageHalfSize'  - size of cropped patch
%   'nOtherObjectSurfaceReflectance' - Number of spectra to be generated
%                   for choosing background surface reflectance (max 999)
%   'luminanceLevels' - luminance levels of target object
%   'reflectanceNumbers' - A row vetor containing Reflectance Numbers of
%                   target object. These are just dummy variables to give a
%                   unique name to each random spectra.
%   'nInsertedLights' - Number of inserted lights
%   'nInsertObjects' - Number of inserted objects (other than target object)
%   'maxAttempts' - maximum number of attempts to find the right recipe
%   'targetPixelThresholdMin' - minimum fraction of target pixels that
%                 should be present in the cropped image.
%   'targetPixelThresholdMax' - maximum fraction of target pixels that
%                 should be present in the cropped image.
%   'otherObjectReflectanceRandom' - boolean to specify if spectra of
%                   background objects is random or not. Default true
%   'illuminantSpectraRandom' - boolean to specify if spectra of
%                   illuminant is random or not. Default true
%   'illuminantSpectrumNotFlat' - boolean to specify illumination spectra 
%                   shape to be not flat, i.e. random, (true= random)
%   'minMeanIlluminantLevel' - Min of mean value of ilumination spectrum
%   'maxMeanIlluminantLevel' - Max of mean value of ilumination spectrum
%   'targetSpectrumNotFlat' - boolean to specify arget spectra 
%                   shape to be not flat, i.e. random, (true= random)
%   'allTargetSpectrumSameShape' - boolean to specify all target spectrum to
%                   be of same shape
%   'targetReflectanceScaledCopies' - boolean to specify target reflectance
%                   shape to be same at each reflectance number. This will
%                   create multiple hue, but the same hue will be repeated
%                   at each luminance level
%   'baseSceneReflectancesSameAcrossInterval' - option to keep the
%       basescene reflectance have the same shape. Needed for psychophysics.
%   'otherObjectReflectancesSameAcrossInterval' - option to keep the
%       other object reflectance same shape. Needed for psychophysics.
%   'lightPositionRandom' - boolean to specify illuminant position is fixed
%                   or not. Default is true. False will only work for 
%                   library-bigball case.
%   'lightScaleRandom' - boolean to specify illuminant scale/size. Default 
%                   is true.
%   'targetPositionRandom' - boolean to specify illuminant scale/size.
%                   Default is true. False will only work for
%                   library-bigball case.
%   'targetScaleRandom' - boolean to specify target scale/size is fixed or
%                   not. Default is true.
%   'targetRotationRandom' - boolean to specify target angular position is 
%                   fixed or not. Default is true. False will only work for 
%   'baseSceneSet'  - Base scenes to be used for renderings. One of these
%                  base scenes is used for each rendering
%   'objectShapeSet'  - Shapes of the target object other inserted objects
%   'lightShapeSet'  - Shapes of the inserted illuminants

%% Want each run to start with its own random seed
rng('shuffle');

%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('outputName','ExampleOutput',@ischar);
parser.addParameter('imageWidth', 320, @isnumeric);
parser.addParameter('imageHeight', 240, @isnumeric);
parser.addParameter('cropImageHalfSize', 25, @isnumeric);
parser.addParameter('nOtherObjectSurfaceReflectance', 100, @isnumeric);
parser.addParameter('luminanceLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', [1 2], @isnumeric);
parser.addParameter('nInsertedLights', 1, @isnumeric);
parser.addParameter('nInsertObjects', 0, @isnumeric);
parser.addParameter('maxAttempts', 30, @isnumeric);
parser.addParameter('targetPixelThresholdMin', 0.1, @isnumeric);
parser.addParameter('targetPixelThresholdMax', 0.6, @isnumeric);
parser.addParameter('otherObjectReflectanceRandom', true, @islogical);
parser.addParameter('illuminantSpectraRandom', true, @islogical);
parser.addParameter('illuminantSpectrumNotFlat', true, @islogical);
parser.addParameter('minMeanIlluminantLevel', 10, @isnumeric);
parser.addParameter('maxMeanIlluminantLevel', 30, @isnumeric);
parser.addParameter('targetSpectrumNotFlat', true, @islogical);
parser.addParameter('allTargetSpectrumSameShape', false, @islogical);
parser.addParameter('targetReflectanceScaledCopies', false, @islogical);
parser.addParameter('baseSceneReflectancesSameAcrossInterval', false, @islogical);
parser.addParameter('otherObjectReflectancesSameAcrossInterval', false, @islogical);
parser.addParameter('lightPositionRandom', true, @islogical);
parser.addParameter('lightScaleRandom', true, @islogical);
parser.addParameter('targetPositionRandom', true, @islogical);
parser.addParameter('targetScaleRandom', true, @islogical);
parser.addParameter('targetRotationRandom', true, @islogical);
parser.addParameter('objectShapeSet', ...
    {'Barrel', 'BigBall', 'ChampagneBottle', 'RingToy', 'SmallBall', 'Xylophone'}, @iscellstr);
parser.addParameter('lightShapeSet', ...
    {'Barrel', 'BigBall', 'ChampagneBottle', 'RingToy', 'SmallBall', 'Xylophone'}, @iscellstr);
parser.addParameter('baseSceneSet', ...
    {'CheckerBoard', 'IndoorPlant', 'Library', 'Mill', 'TableChairs', 'Warehouse'}, @iscellstr);
parser.parse(varargin{:});
imageWidth = parser.Results.imageWidth;
imageHeight = parser.Results.imageHeight;
cropImageHalfSize = parser.Results.cropImageHalfSize;
nOtherObjectSurfaceReflectance = parser.Results.nOtherObjectSurfaceReflectance;
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;
maxAttempts = parser.Results.maxAttempts;
targetPixelThresholdMin = parser.Results.targetPixelThresholdMin;
targetPixelThresholdMax = parser.Results.targetPixelThresholdMax;
objectShapeSet = parser.Results.objectShapeSet;
lightShapeSet = parser.Results.lightShapeSet;
baseSceneSet = parser.Results.baseSceneSet;
otherObjectReflectanceRandom = parser.Results.otherObjectReflectanceRandom;
baseSceneReflectancesSameAcrossInterval = parser.Results.baseSceneReflectancesSameAcrossInterval;
otherObjectReflectancesSameAcrossInterval = parser.Results.otherObjectReflectancesSameAcrossInterval;
illuminantSpectraRandom = parser.Results.illuminantSpectraRandom;
illuminantSpectrumNotFlat = parser.Results.illuminantSpectrumNotFlat;
nInsertedLights = parser.Results.nInsertedLights;
nInsertObjects = parser.Results.nInsertObjects;
nLuminanceLevels = numel(luminanceLevels);
nReflectances = numel(reflectanceNumbers);

%% Basic setup we don't want to expose as parameters.
projectName = 'VirtualWorldColorConstancy';
hints.renderer = 'Mitsuba';
hints.isPlot = false;

%% Set up output
hints.workingFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Working');
originalFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Originals');
if (~exist(originalFolder, 'dir'))
    mkdir(originalFolder);
end

%% HERE IS WHAT I THINK.  THIS CODE WILL CHANGE THE SIZE OF THE IMAGE.

hints.imageHeight = imageHeight;
hints.imageWidth = imageWidth;

%% Configure where to find assets.
aioPrefs.locations = aioLocation( ...
    'name', 'VirtualScenesExampleAssets', ...
    'strategy', 'AioFileSystemStrategy', ...
    'baseDir', fullfile(vseaRoot(), 'examples'));

%% Choose base scene to pick from
nBaseScenes = numel(baseSceneSet);
baseScenes = cell(1, nBaseScenes);
baseSceneInfos = cell(1, nBaseScenes);
for bb = 1:nBaseScenes
    name = baseSceneSet{bb};
    [baseScenes{bb}, baseSceneInfos{bb}] = VseModel.fromAsset('BaseScenes', name, ...
        'aioPrefs', aioPrefs, ...
        'nameFilter', 'blend$');
end

%% Choose shapes to insert.

% this will load object models, like above
nObjectShapes = numel(objectShapeSet);
objectShapes = cell(1, nObjectShapes);
for ss = 1:nObjectShapes
    name = objectShapeSet{ss};
    objectShapes{ss} = VseModel.fromAsset('Objects', name, ...
        'aioPrefs', aioPrefs, ...
        'nameFilter', 'blend$');
end

% this will load light models, like above
nLightShapes = numel(lightShapeSet);
lightShapes = cell(1, nLightShapes);
for ss = 1:nLightShapes
    name = lightShapeSet{ss};
    lightShapes{ss} = VseModel.fromAsset('Objects', name, ...
        'aioPrefs', aioPrefs, ...
        'nameFilter', 'blend$');
end

%% Make some illuminants and store them in the Data/Illuminants/BaseScene folder.
dataBaseDir = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Data');
illuminantsFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Data','Illuminants','BaseScene');
if illuminantSpectraRandom
    if (illuminantSpectrumNotFlat)
        totalRandomLightSpectra = 999;
        makeIlluminants(totalRandomLightSpectra,illuminantsFolder, ...
                parser.Results.minMeanIlluminantLevel, parser.Results.maxMeanIlluminantLevel);
    else
        totalRandomLightSpectra = 10;
        makeFlatIlluminants(totalRandomLightSpectra,illuminantsFolder, ...
                parser.Results.minMeanIlluminantLevel, parser.Results.maxMeanIlluminantLevel);
    end
else
    totalRandomLightSpectra = 1;
    if (illuminantSpectrumNotFlat)
        makeIlluminants(totalRandomLightSpectra,illuminantsFolder, ...
                parser.Results.minMeanIlluminantLevel, parser.Results.maxMeanIlluminantLevel);
    else
        makeFlatIlluminants(totalRandomLightSpectra,illuminantsFolder, ...
                parser.Results.minMeanIlluminantLevel, parser.Results.maxMeanIlluminantLevel);
    end
end

%% Make some reflectances and store them where they want to be
otherObjectFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Data','Reflectances','OtherObjects');
makeOtherObjectReflectance(nOtherObjectSurfaceReflectance,otherObjectFolder);
targetObjectFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Data','Reflectances','TargetObjects');
if (parser.Results.targetSpectrumNotFlat)
    if (parser.Results.allTargetSpectrumSameShape)
        makeSameShapeTargetReflectance(luminanceLevels,reflectanceNumbers, targetObjectFolder);
    elseif (parser.Results.targetReflectanceScaledCopies)
        makeTargetReflectanceScaledCopies(luminanceLevels,reflectanceNumbers, targetObjectFolder)
    else
        makeTargetReflectance(luminanceLevels, reflectanceNumbers, targetObjectFolder);
    end
else
    makeFlatTargetReflectance(luminanceLevels, reflectanceNumbers, targetObjectFolder);
end

%%
% Choose illuminant spectra from the illuminants folder.
illuminantsLocations.config.baseDir = dataBaseDir;
illuminantsLocations.name = 'ToyVirtualWorldIlluminants';
illuminantsLocations.strategy = 'AioFileSystemStrategy';
illuminantsAioPrefs = aioPrefs;
illuminantsAioPrefs.locations = illuminantsLocations;
illuminantSpectra = aioGetFiles('Illuminants', 'BaseScene', ...
    'aioPrefs', illuminantsAioPrefs, ...
    'fullPaths', false);

%% Choose Reflectance for scene overall
otherObjectLocations.config.baseDir = dataBaseDir;
otherObjectLocations.name = 'ToyVirtualWorldReflectances';
otherObjectLocations.strategy = 'AioFileSystemStrategy';
otherObjectAioPrefs = aioPrefs;
otherObjectAioPrefs.locations = otherObjectLocations;
otherObjectReflectances = aioGetFiles('Reflectances', 'OtherObjects', ...
    'aioPrefs', otherObjectAioPrefs, ...
    'fullPaths', false);
baseSceneReflectances = otherObjectReflectances;


%% Predefine random orders for the case where the two intervals on a trial have the same background reflectances
for ii = 1:nReflectances
    baseSceneReflectanceRandomOrder(ii,:) = randperm(length(otherObjectReflectances));
end

for ii = 1:nReflectances
    otherObjectReflectanceRandomOrder(ii,:) = randperm(length(otherObjectReflectances));
end

%% Choose Reflectance for target object overall
targetLocations.config.baseDir = dataBaseDir;
targetLocations.name = 'ToyVirtualWorldTarget';
targetLocations.strategy = 'AioFileSystemStrategy';
targetAioPrefs = aioPrefs;
targetAioPrefs.locations = targetLocations;
targetObjectReflectance = aioGetFiles('Reflectances', 'TargetObjects', ...
    'aioPrefs', targetAioPrefs, ...
    'fullPaths', false);

%% Assemble recipies by combinations of target luminances reflectances.
nScenes = nLuminanceLevels * nReflectances;
sceneRecord = struct( ...
    'targetLuminanceLevel', [], ...
    'reflectanceNumber', [],  ...
    'nAttempts', cell(1, nScenes), ...
    'choices', [], ...
    'hints', hints, ...
    'rejected', [], ...
    'recipe', [], ...
    'styles', []);

% pre-fill luminance and reflectance conditions per scene
% so that we can unroll the nested loops below
for ll = 1:nLuminanceLevels
    targetLuminanceLevel = luminanceLevels(ll);
    for rr = 1:nReflectances
        reflectanceNumber = reflectanceNumbers(rr);
        
        sceneIndex = rr + (ll-1)*nReflectances;
        sceneRecord(sceneIndex).targetLuminanceLevel = targetLuminanceLevel;
        sceneRecord(sceneIndex).reflectanceNumber = reflectanceNumber;
        sceneRecord(sceneIndex).reflectanceIndex = rr;
    end
end

% iterate scene records with one parfor loop
% Matlab does not support nested parfor loops
parfor sceneIndex = 1:nScenes
    workingRecord = sceneRecord(sceneIndex);
    
    try
        targetLuminanceLevel = workingRecord.targetLuminanceLevel;
        reflectanceNumber = workingRecord.reflectanceNumber;
        reflectanceIndex = workingRecord.reflectanceIndex;
        
        for attempt = 1:maxAttempts
            
            %% Pick the base scene randomly.
            bIndex = randi(size(baseSceneSet, 2), 1);
            %             workingRecord.choices.baseSceneName = baseSceneSet{bIndex};
            %             sceneData = rtbReadMetadata(workingRecord.choices.baseSceneName);
            
            sceneInfo = baseSceneInfos{bIndex};
            workingRecord.choices.baseSceneName = sceneInfo.name;
            sceneData = baseScenes{bIndex}.copy('name', workingRecord.choices.baseSceneName);
            
            
            %% Pick the target object randomly.
            targetShapeIndex = randi(nObjectShapes, 1);
            targetShapeName = objectShapeSet{targetShapeIndex};
            
            %% Choose a unique name for this recipe.
            recipeName = FormatRecipeName( ...
                targetLuminanceLevel, ...
                reflectanceNumber, ...
                targetShapeName, ...
                workingRecord.choices.baseSceneName);
            workingRecord.hints.recipeName = recipeName;
            
            %% Pick other objects and Light shapes to insert
            shapeIndexes = randi(nObjectShapes, [1, nInsertObjects+1]);
            
            %% For each shape insert, choose a random spatial transformation.
            insertShapes = cell(1, nInsertObjects+1);
            
            targetShape = objectShapes{targetShapeIndex};
            
            if parser.Results.targetPositionRandom
                targetRotationX = randi([0, 359]);
                targetRotationY = randi([0, 359]);
                targetRotationZ = randi([0, 359]);
            else
                % this was chosen for the mill-ringtoy case by Vijay Singh
                targetRotationX = 0;
                targetRotationY = 233;
                targetRotationZ = 183;
            end

            if parser.Results.targetPositionRandom
                targetPosition = GetRandomPosition([0 0; 0 0; 0 0], sceneInfo.objectBox);
            else
                % using fixed object position that works for the Library base scene
%              targetPosition = [ -0.010709 4.927981 0.482899]; % BigBall-Library Case 1  
             targetPosition = [ 1.510709 5.527981 2.482899]; % BigBall-Library Case 2
%              targetPosition = [ -0.510709 0.0527981 0.482899]; % BigBall-Library Case 3
%              targetPosition = [-2.626092 -6.054515 1.223028]; % BigBall-Mill Case 4
            end
            
            if parser.Results.targetScaleRandom
                targetScale = 0.3 + rand()/2;
            else
%               targetScale =  1; % BigBall-Library Case 1  
              targetScale =  1; % BigBall-Library Case 2  
%               targetScale =  0.5; % BigBall-Library Case 3
%               targetScale =  1; % BigBall-Mill Case 4
            end            
            
            transformation = mexximpScale(targetScale) ...
                * mexximpRotate([1 0 0], targetRotationX) ...
                * mexximpRotate([0 1 0], targetRotationY) ...
                * mexximpRotate([0 0 1], targetRotationZ) ...
                * mexximpTranslate(targetPosition);
            
            insertShapes{1} = targetShape.copy( ...
                'name', 'shape-01', ...
                'transformation', transformation);
 
% % Store the shape, locations, rotation, etc. of the inserted objects in a
% conditions.txt file
% 
            % Basic setupe of the conditions.txt file
            allNames = {'imageName', 'groupName'};
            allValues = cat(1, {'normal', 'normal'}, {'mask', 'mask'});
    
            allNames = cat(2, allNames);
            allValues = cat(2, allValues);

            % Setup fo the target object position, rotation and scale, etc
            % for the conditions file
            objectColumn = sprintf('object-%d', 1);
            positionColumn = sprintf('object-position-%d', 1);
            rotationColumn = sprintf('object-rotation-%d', 1);
            scaleColumn = sprintf('object-scale-%d', 1);
            
            varNames = {objectColumn, positionColumn, rotationColumn, scaleColumn};
            allNames = cat(2, allNames, varNames);
            
            varValues = {targetShape.name, ...
                targetPosition, ...
                [targetRotationX targetRotationY targetRotationZ], ...
                targetScale};
            allValues = cat(2, allValues, repmat(varValues, 2, 1));

            
            for sss = 2:(nInsertObjects+1)
                shape = objectShapes{shapeIndexes(sss)};
                
                rotationX = randi([0, 359]);
                rotationY = randi([0, 359]);
                rotationZ = randi([0, 359]);
                position = GetRandomPosition([0 0; 0 0; 0 0], sceneInfo.objectBox);
                scale = 0.3 + rand()/2;
                transformation = mexximpScale(scale) ...
                    * mexximpRotate([1 0 0], rotationX) ...
                    * mexximpRotate([0 1 0], rotationY) ...
                    * mexximpRotate([0 0 1], rotationZ) ...
                    * mexximpTranslate(position);
                
                shapeName = sprintf('shape-%d', sss);
                insertShapes{sss} = shape.copy( ...
                    'name', shapeName, ...
                    'transformation', transformation);

                % Write conditions file for saving the position, scale and
                % rotation of the objects
                objectColumn = sprintf('object-%d', sss);
                positionColumn = sprintf('object-position-%d', sss);
                rotationColumn = sprintf('object-rotation-%d', sss);
                scaleColumn = sprintf('object-scale-%d', sss);
                
                varNames = {objectColumn, positionColumn, rotationColumn, scaleColumn};
                allNames = cat(2, allNames, varNames);
                
                varValues = {shape.name, ...
                    position, ...
                    [rotationX rotationY rotationZ], ...
                    scale};
                allValues = cat(2, allValues, repmat(varValues, 2, 1));

            end
            
            %% Position the camera.
            %   "eye" position is from the first camera "slot"
            %   "target" position is the target object's position
            %   "up" direction is from the first camera "slot"
            eye = sceneInfo.cameraSlots(1).position;
            up = sceneInfo.cameraSlots(1).up;
            lookAt = mexximpLookAt(eye, targetPosition, up);
            
            cameraName = sceneData.model.cameras(1).name;
            isCameraNode = strcmp(cameraName, {sceneData.model.rootNode.children.name});
            sceneData.model.rootNode.children(isCameraNode).transformation = lookAt;
            
            %% For each light insert, choose a random spatial transformation.
            lightIndexes = randi(nLightShapes, [1, nInsertedLights]);
            
            insertLights = cell(1, nInsertedLights);
            for ll = 1:nInsertedLights
                light = lightShapes{lightIndexes(ll)};
                
                rotationX = randi([0, 359]);
                rotationY = randi([0, 359]);
                rotationZ = randi([0, 359]);

                if parser.Results.lightPositionRandom
                    position = GetRandomPosition(sceneInfo.lightExcludeBox, sceneInfo.lightBox);
                else
                    % using fixed light position that works for the Library base scene
                    position = [-6.504209 18.729564 5.017080];
                        
                end
                
                if parser.Results.lightScaleRandom
                    scale = 0.3 + rand()/2;
                else
                    scale = 1;
                end
                
                transformation = mexximpScale(scale) ...
                    * mexximpRotate([1 0 0], rotationX) ...
                    * mexximpRotate([0 1 0], rotationY) ...
                    * mexximpRotate([0 0 1], rotationZ) ...
                    * mexximpTranslate(position);
                
                lightName = sprintf('light-%d', ll);
                insertLights{ll} = light.copy(...
                    'name', lightName, ...
                    'transformation', transformation);
                
                % Write the conditions file for saving position of the
                % objects and lights
                lightColumn = sprintf('light-%d', ll);
                positionColumn = sprintf('light-position-%d', ll);
                rotationColumn = sprintf('light-rotation-%d', ll);
                scaleColumn = sprintf('light-scale-%d', ll);
                
                varNames = {lightColumn, positionColumn, rotationColumn, scaleColumn};
                allNames = cat(2, allNames, varNames);
                
                varValues = {light.name, ...
                    position, ...
                    [rotationX rotationY rotationZ], ...
                    scale};
                allValues = cat(2, allValues, repmat(varValues, 2, 1));

            end
            conditionsFile = fullfile(hints.workingFolder,recipeName,'Conditions.txt');
            rtbWriteConditionsFile(conditionsFile, allNames, allValues);            
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
            workingRecord.styles.mask = {quickRendering, allBlackDiffuse, firstShapeEmitter};
            
            %% Do the mask rendering and reject if required
            innerModels = [insertShapes{:} insertLights{:}];
            workingRecord.recipe = vseBuildRecipe(sceneData, innerModels, workingRecord.styles, 'hints', workingRecord.hints);
            
            % generate scene files and render
            workingRecord.recipe = rtbExecuteRecipe(workingRecord.recipe);
            
            workingRecord.rejected = CheckTargetObjectOcclusion(workingRecord.recipe, ...
                'imageWidth', imageWidth, ...
                'imageHeight', imageHeight, ...
                'targetPixelThresholdMin', targetPixelThresholdMin, ...
                'targetPixelThresholdMax', targetPixelThresholdMax, ...
                'totalBoundingBoxPixels', (2*cropImageHalfSize+1)^2);
            if workingRecord.rejected
                % delete this recipe and try again
                rejectedFolder = rtbWorkingFolder('folder','', 'hint', workingRecord.hints);
                [~, ~] = rmdir(rejectedFolder, 's');
                continue;
            else
                
                %% Choose styles for the full radiance rendering.
                fullRendering = VwccMitsubaRenderingQuality( ...
                    'integratorPluginType', 'path', ...
                    'samplerPluginType', 'ldsampler');
                fullRendering.addIntegratorProperty('maxDepth', 'integer', 10);
                fullRendering.addSamplerProperty('sampleCount', 'integer', 512);
                
                % bless specific meshes in the base scene as area lights
                nBaseLights = numel(sceneInfo.lightIds);
                baseLightNames = cell(1, nBaseLights);
                for ll = 1:nBaseLights
                    lightId = sceneInfo.lightIds{ll};
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
                areaLightSpectra.resourceFolder = dataBaseDir;
                if illuminantSpectraRandom
                    tempIlluminantSpectra = illuminantSpectra((randperm(length(illuminantSpectra))));
                else
                    tempIlluminantSpectra = illuminantSpectra;
                end
                areaLightSpectra.addManySpectra(tempIlluminantSpectra);
                
                % assign spectra to materials in the base scene
                %
                % note setting of resourceFolder to point to where the
                % files with the spectra live.  This is necessary so
                % that when the recipe gets built, these spectral files
                % can be found and copied into the right place.
                baseSceneDiffuse = VseMitsubaDiffuseMaterials( ...
                    'name', 'baseSceneDiffuse', ...
                    'applyToInnerModels', false);
                baseSceneDiffuse.resourceFolder = dataBaseDir;
                if otherObjectReflectanceRandom
                    if baseSceneReflectancesSameAcrossInterval
                        tempBaseSceneReflectances = baseSceneReflectances(baseSceneReflectanceRandomOrder(reflectanceIndex,:));
                    else
                        tempBaseSceneReflectances = baseSceneReflectances((randperm(length(baseSceneReflectances))));
                    end
                else
                    tempBaseSceneReflectances = baseSceneReflectances;
                end
                baseSceneDiffuse.addManySpectra(tempBaseSceneReflectances);
                
                % assign spectra to all materials of inserted shapes
                insertedDiffuse = VseMitsubaDiffuseMaterials( ...
                    'name', 'insertedDiffuse', ...
                    'modelNameFilter', 'shape-',...
                    'applyToOuterModels', false);
                insertedDiffuse.resourceFolder = dataBaseDir;
                if otherObjectReflectanceRandom
                    if otherObjectReflectancesSameAcrossInterval
                        tempOtherObjectReflectances = otherObjectReflectances(otherObjectReflectanceRandomOrder(reflectanceIndex,:));
                    else
                        tempOtherObjectReflectances = otherObjectReflectances((randperm(length(otherObjectReflectances))));
                    end
                else
                    tempOtherObjectReflectances = otherObjectReflectances;
                end
                insertedDiffuse.addManySpectra(tempOtherObjectReflectances);
                
                % assign a specific reflectance to the target object
                targetDiffuse = VseMitsubaDiffuseMaterials( ...
                    'name', 'targetDiffuse', ...
                    'applyToOuterModels', false, ...
                    'modelNameFilter', 'shape-01');
                % targetDiffuse.addSpectrum(targetObjectReflectance);
                targetDiffuse.resourceFolder = dataBaseDir;
                reflectanceFileName = sprintf('luminance-%.4f-reflectance-%03d.spd', ...
                    targetLuminanceLevel, reflectanceNumber);
                targetDiffuse.addManySpectra({reflectanceFileName});
                
                workingRecord.styles.normal = {fullRendering, ...
                    blessBaseLights, blessInsertedLights, areaLightSpectra, ...
                    baseSceneDiffuse, insertedDiffuse, targetDiffuse};
                
                %% Do the final rendering
                innerModels = [insertShapes{:} insertLights{:}];
                workingRecord.recipe = vseBuildRecipe(sceneData, innerModels, workingRecord.styles, 'hints', workingRecord.hints);
                
                % generate scene files and render
                workingRecord.recipe = rtbExecuteRecipe(workingRecord.recipe);
                
                % move on to save this recipe
                break;
            end
        end
        
        % keep track of attempts and rejections
        workingRecord.nAttempts = attempt;
        
        if workingRecord.rejected
            warning('%s rejected after %d attempts!', ...
                workingRecord.hints.recipeName, attempt);
        else
            fprintf('%s accepted after %d attempts.\n', ...
                workingRecord.hints.recipeName, attempt);
            
            % save the recipe to the recipesFolder
            archiveFile = fullfile(originalFolder, workingRecord.hints.recipeName);
            excludeFolders = {'scenes', 'renderings', 'images'};
            workingRecord.recipe.input.sceneRecord = workingRecord;
            workingRecord.recipe.input.hints.whichConditions = [];
            rtbPackUpRecipe(workingRecord.recipe, archiveFile, 'ignoreFolders', excludeFolders);
        end
        
        sceneRecord(sceneIndex) = workingRecord;
        
    catch err
        SaveToyVirutalWorldError(originalFolder, err, workingRecord.recipe, workingRecord);
    end
end
