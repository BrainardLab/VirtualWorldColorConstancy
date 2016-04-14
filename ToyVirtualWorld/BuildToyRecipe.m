%% Build a new WardLand recipe.
%   @param defaultMappings a stub mappings file to append to
%   @param choices struct of random scene picks as from GetWardLandChoices()
%   @param auxiliaryIds cell array of strings of auxiliary object ids
%   @param auxiliaryObjects cell array auxiliary object descriptions
%   @param lookAt for the camera, 'eyeX eyeY eyeZ targetX targetY targetZ upX upY upZ'
%   @param hints struct of RenderToolbox3 options as from GetDefaultHints()
%
% @details
% Packs up the given WardLand @a choices into a functional recipe that may
% be executed.  @a defaultMappings should be a stub mappings file that will
% be copied and appened to for the new recipe.  For example, see
% VirtualScenesToolbox/MiscellaneousData/DefaultMappings.txt.
%
% @details
% If @a hints is provided, it may specify certain rendering options, like
% the output film size or which renderer to use.
%
% @details
% The new recipe will have two conditions for rendering.  The "normal"
% condition will apply matte materials to each object in the scene.
% The "mask" condition will make every object in the scene black, except
% for the first inserted object, which will be white.  This will allow us
% to identify the target object in subsequent renderings, and determine
% whether the target object is suffucuently visible to the camera.
%
% @details
% Returns a new WardLand recipe suitable for use with other ToyRecipe
% functions.
%
% @details
% Usage:
%   recipe = BuildToyRecipe(defaultMappings, choices, auxiliaryIds, auxiliaryObjects, lookAt, hints)
%
% @ingroup WardLand
function recipe = BuildToyRecipe(defaultMappings, choices, auxiliaryIds, auxiliaryObjects, lookAt, hints)

if nargin < 3 || isempty(hints)
    auxiliaryIds = {};
end

if nargin < 4 || isempty(hints)
    auxiliaryObjects = {};
end

if nargin < 5 || isempty(lookAt)
    lookAt = '';
end

if nargin < 6 || isempty(hints)
    hints = GetDefaultHints();
else
    hints = GetDefaultHints(hints);
end

%% Augment batch renderer options.
hints.remodeler = 'InsertObjectRemodeler';
ChangeToWorkingFolder(hints);
conditionsFile = [hints.recipeName '-Conditions.txt'];
mappingsFile = [hints.recipeName '-Mappings.txt'];
sceneMetadata = ReadMetadata(choices.baseSceneName);
prefName = 'VirtualScenes';

%% Copy in the parent scene file as a portable recipe resource.
modelAbsPath = GetVirtualScenesRepositoryPath(sceneMetadata.relativePath);
[~, modelFile, modelExt] = fileparts(modelAbsPath);

resources = GetWorkingFolder('resources', false, hints);
parentSceneAbsPath = fullfile(resources, [modelFile, modelExt]);

if exist(parentSceneAbsPath, 'file')
    delete(parentSceneAbsPath);
end
copyfile(modelAbsPath, parentSceneAbsPath);

%% Set up the base scene lights.
% turn off base scene and inserted lights when making pixel masks
blackArea = BuildDesription('light', 'area', ...
    {'intensity'}, ...
    {'300:0 800:0'}, ...
    {'spectrum'});
maskBaseSceneLightSet = cell(1, numel(sceneMetadata.lightIds));
[maskBaseSceneLightSet{:}] = deal(blackArea);

maskInsertedLightSet = cell(1, numel(choices.insertedLights.names));
[maskInsertedLightSet{:}] = deal(blackArea);

%% Set up the "flash" light for making object pixel masks.
% use a uniform spectrum for the "flash"
flashModel = 'CameraFlash';
flashMetadata = ReadMetadata(flashModel);
whiteArea = BuildDesription('light', 'area', ...
    {'intensity'}, ...
    {'300:1 800:1'}, ...
    {'spectrum'});
flashLightId = ['light-flash-' flashMetadata.lightIds{1}];

% use a uniform reflectance for the "flash"
whiteMatte = BuildDesription('material', 'matte', ...
    {'diffuseReflectance'}, ...
    {'300:1 800:1'}, ...
    {'spectrum'});
flashMaterialId = ['light-flash-' flashMetadata.materialIds{1}];

% position the flash relative to the camera
flashPosition = 'Camera';
flashRotation = 'Camera';
flashScale = 'Camera';

%% Set up materials for the full "normal" rendering.

% build a grand list of material and light ids, matte, and ward materials
allMaterialIds = sceneMetadata.materialIds;
allSceneMatteMaterials = choices.baseSceneMatteMaterials;
allSceneInsertedLightIds = cell(1, numel(choices.insertedLights.names));

% inserted object material ids get prefixed with the object number
nInserted = numel(choices.insertedObjects.names);
for oo = 1:nInserted
    idPrefix = sprintf('object-%d-', oo);
    objectMetadata = ReadMetadata(choices.insertedObjects.names{oo});
    nObjectMaterials = numel(objectMetadata.materialIds);
    objectMaterialIds = cell(1, nObjectMaterials);
    for mm = 1:nObjectMaterials
        objectMaterialIds{mm} = [idPrefix objectMetadata.materialIds{mm}];
    end
    allMaterialIds = cat(2, allMaterialIds, objectMaterialIds);
    allSceneMatteMaterials = cat(2, allSceneMatteMaterials, ...
        choices.insertedObjects.matteMaterialSets{oo});
end

% inserted light material ids get prefixed with the light number
nInserted = numel(choices.insertedLights.names);
for oo = 1:nInserted
    idPrefix = sprintf('light-%d-', oo);
    objectMetadata = ReadMetadata(choices.insertedLights.names{oo});
    nObjectMaterials = numel(objectMetadata.materialIds);
    objectMaterialIds = cell(1, nObjectMaterials);
    for mm = 1:nObjectMaterials
        objectMaterialIds{mm} = [idPrefix objectMetadata.materialIds{mm}];
    end
    allMaterialIds = cat(2, allMaterialIds, objectMaterialIds);
    allSceneMatteMaterials = cat(2, allSceneMatteMaterials, ...
        choices.insertedLights.matteMaterialSets{oo});
    allSceneInsertedLightIds{oo} = [idPrefix objectMetadata.lightIds{1}];
end

%% Set up materials for the "mask" rendering.

% start by making all materials black
blackMatte = BuildDesription('material', 'matte', ...
    {'diffuseReflectance'}, ...
    {'300:0 800:0'}, ...
    {'spectrum'});
nMaterials = numel(allSceneMatteMaterials);
allMaskMaterials = cell(1, nMaterials);
[allMaskMaterials{:}] = deal(blackMatte);

% make the target object white
targetObjectIndex = 1 + numel(sceneMetadata.materialIds);
allMaskMaterials{targetObjectIndex} = whiteMatte;

%% Optionally append a lookAt transform for the Camera.
if isempty(lookAt)
    freshMappings = defaultMappings;
else
    descriptions = cell(1, 6);
    descriptions{1}.path = {':translate|sid=location'};
    descriptions{1}.value = '0 0 0';
    descriptions{2}.path = {':rotate|sid=rotationZ'};
    descriptions{2}.value = '0 0 1 0';
    descriptions{3}.path = {':rotate|sid=rotationY'};
    descriptions{3}.value = '0 1 0 0';
    descriptions{4}.path = {':rotate|sid=rotationX'};
    descriptions{4}.value = '1 0 0 0';
    descriptions{5}.path = {':scale|sid=scale'};
    descriptions{5}.value = '1 1 1';
    descriptions{6}.path = {':lookat|sid=lookat'};
    descriptions{6}.value = lookAt;
    descriptions{7}.path = {':scale|sid=postScale'};
    descriptions{7}.value = '-1 1 -1';
    
    ids = cell(1, numel(descriptions));
    [ids{:}] = deal('Camera');
    
    AppendMappings(defaultMappings, mappingsFile, ...
        ids, descriptions, 'Collada', 'reposition the camera');
    freshMappings = mappingsFile;
end

%% Write out config, materials, and lights to a big mappings file.
configs = getpref(prefName, 'rendererConfigs');

% full "normal" rendering
AppendMappings(freshMappings, mappingsFile, ...
    configs.Mitsuba.ids, configs.Mitsuba.full.descriptions, ...
    [configs.Mitsuba.full.blockName ' normal'], 'config');
AppendMappings(mappingsFile, mappingsFile, ...
    configs.PBRT.ids, configs.PBRT.full.descriptions, ...
    [configs.PBRT.full.blockName ' normal'], 'config');
AppendMappings(mappingsFile, mappingsFile, ...
    sceneMetadata.lightIds, choices.baseSceneLights, 'Generic normal', 'base scene lights');
AppendMappings(mappingsFile, mappingsFile, ...
    allSceneInsertedLightIds, choices.insertedLights.lightSpectra, 'Generic normal', 'inserted lights');
AppendMappings(mappingsFile, mappingsFile, ...
    allMaterialIds, allSceneMatteMaterials, 'Generic normal', 'materials');

% quick "mask" rendering
AppendMappings(mappingsFile, mappingsFile, ...
    configs.Mitsuba.ids, configs.Mitsuba.full.descriptions, ...
    [configs.Mitsuba.quick.blockName ' mask'], 'config');
AppendMappings(mappingsFile, mappingsFile, ...
    configs.PBRT.ids, configs.PBRT.quick.descriptions, ...
    [configs.PBRT.full.blockName ' mask'], 'config');
AppendMappings(mappingsFile, mappingsFile, ...
    allMaterialIds, allMaskMaterials, 'Generic mask', 'base scene lights');
AppendMappings(mappingsFile, mappingsFile, ...
    allSceneInsertedLightIds, maskInsertedLightSet, 'Generic mask', 'inserted lights');
AppendMappings(mappingsFile, mappingsFile, ...
    sceneMetadata.lightIds, maskBaseSceneLightSet, 'Generic mask', 'materials');
AppendMappings(mappingsFile, mappingsFile, ...
    {flashLightId}, {whiteArea}, 'Generic mask', 'flash light');
AppendMappings(mappingsFile, mappingsFile, ...
    {flashMaterialId}, {whiteMatte}, 'Generic mask', 'flash material');

% any auxiliary objects
AppendMappings(mappingsFile, mappingsFile, ...
    auxiliaryIds, auxiliaryObjects, 'Generic', 'auxiliary');

%% Write conditions for inserted objects.

% basic conditions file columns
allNames = {'imageName', 'groupName'};
allValues = cat(1, {'normal', 'normal'}, {'mask', 'mask'});

% columns for the inserted flash light
flashNames = {'light-flash', 'position-flash', 'rotation-flash', 'scale-flash'};
flashSceneValues = {'none', 'none', 'none', 'none'};
flashMaskValues = {flashModel, flashPosition, flashRotation, flashScale};
flashValues = cat(1, flashSceneValues, flashMaskValues);

allNames = cat(2, allNames, flashNames);
allValues = cat(2, allValues, flashValues);

% append columns for each inserted object
nInserted = numel(choices.insertedObjects.names);
for oo = 1:nInserted
    objectColumn = sprintf('object-%d', oo);
    positionColumn = sprintf('object-position-%d', oo);
    rotationColumn = sprintf('object-rotation-%d', oo);
    scaleColumn = sprintf('object-scale-%d', oo);
    
    varNames = {objectColumn, positionColumn, rotationColumn, scaleColumn};
    allNames = cat(2, allNames, varNames);
    
    varValues = {choices.insertedObjects.names{oo}, ...
        choices.insertedObjects.positions{oo}, ...
        choices.insertedObjects.rotations{oo}, ...
        choices.insertedObjects.scales{oo}};
    allValues = cat(2, allValues, repmat(varValues, 2, 1));
end

% append columns for each inserted light
nInserted = numel(choices.insertedLights.names);
for oo = 1:nInserted
    lightColumn = sprintf('light-%d', oo);
    positionColumn = sprintf('light-position-%d', oo);
    rotationColumn = sprintf('light-rotation-%d', oo);
    scaleColumn = sprintf('light-scale-%d', oo);
    
    varNames = {lightColumn, positionColumn, rotationColumn, scaleColumn};
    allNames = cat(2, allNames, varNames);
    
    varValues = {choices.insertedLights.names{oo}, ...
        choices.insertedLights.positions{oo}, ...
        choices.insertedLights.rotations{oo}, ...
        choices.insertedLights.scales{oo}};
    allValues = cat(2, allValues, repmat(varValues, 2, 1));
end

% write out the conditions file
WriteConditionsFile(conditionsFile, allNames, allValues);

%% Pack it all up in a recipe.
executive = { ...
    @MakeRecipeSceneFiles, ...
    @MakeRecipeRenderings, ...
    @(recipe)MakeRecipeMontage(recipe, 100, true), ...
    };

parentSceneRelativePath = GetWorkingRelativePath(parentSceneAbsPath, hints);
recipe = NewRecipe([], executive, parentSceneRelativePath, ...
    conditionsFile, mappingsFile, hints);

% remember how materials were assigned
recipe.processing.allMaterialIds = allMaterialIds;
recipe.processing.allSceneMatteMaterials = allSceneMatteMaterials;
recipe.processing.allMaskMaterials = allMaskMaterials;
recipe.processing.allSceneInsertedLightIds = allSceneInsertedLightIds;

