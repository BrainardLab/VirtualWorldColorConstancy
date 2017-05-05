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
%   'luminanceLevels' - luminance levels of target object
%   'reflectanceNumbers' - A row vetor containing Reflectance Numbers of 
%                   target object. These are just dummy variables to give a
%                   unique name to each random spectra.
%   'otherObjectReflectanceRandom' - boolean to specify if spectra of 
%                   background objects is random or not. Default true
%   'illuminantSpectraRandom' - boolean to specify if spectra of 
%                   illuminant is random or not. Default true
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
%   'baseSceneSet'  - Base scenes to be used for renderings. One of these
%                  base scenes is used for each rendering
%   'shapeSet'  - Shapes of the object that can be used for target
%                      object, illuminant and other inserted objects
%   'maxAttempts'- Maximum number of attempts allowed for finding a recipe
%                 for with no occlusion of the target
%   'targetPixelThresholdMin' - minimum fraction of target pixels that
%                 should be present in the cropped image.
%   'targetPixelThresholdMax' - maximum fraction of target pixels that
%                 should be present in the cropped image.

%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('outputName','ExampleOutput',@ischar);
parser.addParameter('imageWidth', 320, @isnumeric);
parser.addParameter('imageHeight', 240, @isnumeric);
parser.addParameter('cropImageHalfSize', 25, @isnumeric);
parser.addParameter('nOtherObjectSurfaceReflectance', 100, @isnumeric);
parser.addParameter('luminanceLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', [1 2], @isnumeric);
parser.addParameter('maxAttempts', 30, @isnumeric);
parser.addParameter('targetPixelThresholdMin', 0.1, @isnumeric);
parser.addParameter('targetPixelThresholdMax', 0.6, @isnumeric);
parser.addParameter('otherObjectReflectanceRandom', true, @islogical);
parser.addParameter('illuminantSpectraRandom', true, @islogical);
parser.addParameter('illuminantSpectrumNotFlat', true, @islogical);
parser.addParameter('targetSpectrumNotFlat', true, @islogical);
parser.addParameter('lightPositionRandom', true, @islogical);
parser.addParameter('lightScaleRandom', true, @islogical);
parser.addParameter('targetPositionRandom', true, @islogical);
parser.addParameter('targetScaleRandom', true, @islogical);
parser.addParameter('shapeSet', ...
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
shapeSet = parser.Results.shapeSet;
baseSceneSet = parser.Results.baseSceneSet;
otherObjectReflectanceRandom = parser.Results.otherObjectReflectanceRandom;
illuminantSpectraRandom = parser.Results.illuminantSpectraRandom;
illuminantSpectrumNotFlat = parser.Results.illuminantSpectrumNotFlat;

nLuminanceLevels = numel(luminanceLevels);
nReflectances = numel(reflectanceNumbers);
nShapes = numel(shapeSet);

%% Basic setup we don't want to expose as parameters.
projectName = 'VirtualWorldColorConstancy';
hints.renderer = 'Mitsuba';
hints.isPlot = false;

%% This doesn't work anymore because we don't have function VirtualScenesRoot.
% 
% Maybe we don't need the defaultMappings anymore.  We'll have to see.
%
% defaultMappings = fullfile(VirtualScenesRoot(), 'MiscellaneousData', 'DefaultMappings.txt');

% Set up output
hints.workingFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Working');
originalFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Originals');
if (~exist(originalFolder, 'dir'))
    mkdir(originalFolder);
end

%% Make some illuminants and store them in the Data/Illuminants folder.
illuminantsFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Data','Illuminants');
if illuminantSpectraRandom    
    if (illuminantSpectrumNotFlat)
        totalRandomLightSpectra = 100;
        makeIlluminants(totalRandomLightSpectra,illuminantsFolder);
    else
        totalRandomLightSpectra = 10;
        makeFlatIlluminants(totalRandomLightSpectra,illuminantsFolder, 1, 300);
    end
else
    totalRandomLightSpectra = 1;
    if (illuminantSpectrumNotFlat)
        makeIlluminants(totalRandomLightSpectra,illuminantsFolder);
    else
        makeFlatIlluminants(totalRandomLightSpectra,illuminantsFolder, 150, 150);
    end
end

% Choose illuminant spectra from the illuminants folder.
lightSpectra = getIlluminantSpectra(hints);
nLightSpectra = numel(lightSpectra);

% flat reflectance for illuminants
matteIlluminant = rtbBuildDesription('material', 'matte', ...
    {'diffuseReflectance'}, ...
    {'300:0.5 800:0.5'}, ...
    {'spectrum'});
wardIlluminant = rtbBuildDesription('material', 'anisoward', ...
    {'diffuseReflectance', 'specularReflectance'}, ...
    {'300:0.5 800:0.5', '300:0.1 800:0.1'}, ...
    {'spectrum', 'spectrum'});

%% Make some reflectances and store them where they want to be
otherObjectFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Data','Reflectances','OtherObjects');
makeOtherObjectReflectance(nOtherObjectSurfaceReflectance,otherObjectFolder);

targetObjectFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Data','Reflectances','TargetObjects');
if (parser.Results.targetSpectrumNotFlat)
    makeTargetReflectance(luminanceLevels, reflectanceNumbers, targetObjectFolder);
else
    makeFlatTargetReflectance(luminanceLevels, reflectanceNumbers, targetObjectFolder);
end

%% Assemble recipies by combinations of target luminances reflectances.
nScenes = nLuminanceLevels * nReflectances;
sceneRecord = struct( ...
    'targetLuminanceLevel', [], ...
    'reflectanceNumber', [],  ...
    'nAttempts', cell(1, nScenes), ...
    'choices', [], ...
    'hints', hints, ...
    'rejected', [], ...
    'recipe', []);

% pre-fill luminance and reflectance conditions per scene
% so that we can unroll the nested loops below
for ll = 1:nLuminanceLevels
    targetLuminanceLevel = luminanceLevels(ll);
    for rr = 1:nReflectances
        reflectanceNumber = reflectanceNumbers(rr);
        
        sceneIndex = rr + (ll-1)*nReflectances;
        sceneRecord(sceneIndex).targetLuminanceLevel = targetLuminanceLevel;
        sceneRecord(sceneIndex).reflectanceNumber = reflectanceNumber;
    end
end

% iterate scene records with one parfor loop
% Matlab does not support nested parfor loops
parfor sceneIndex = 1:nScenes
    workingRecord = sceneRecord(sceneIndex);
    
    try
        targetLuminanceLevel = workingRecord.targetLuminanceLevel;
        reflectanceNumber = workingRecord.reflectanceNumber;
        
        for attempt = 1:maxAttempts
            
            %% Pick the base scene randomly.
            bIndex = randi(size(baseSceneSet, 2), 1);
            workingRecord.choices.baseSceneName = baseSceneSet{bIndex};
            sceneData = rtbReadMetadata(workingRecord.choices.baseSceneName);
            
            %% Pick the target object randomly.
            targetShapeIndex = randi(nShapes, 1);
            targetShapeName = shapeSet{targetShapeIndex};
            
            %% Choose a unique name for this recipe.
            recipeName = FormatRecipeName( ...
                targetLuminanceLevel, ...
                reflectanceNumber, ...
                targetShapeName, ...
                workingRecord.choices.baseSceneName);
            workingRecord.hints.recipeName = recipeName;
            
            
            %% Assign a reflectance to each object in the base scene.
            nBaseMaterials = numel(sceneData.materialIds);
            workingRecord.choices.baseSceneMatteMaterials = cell(1, nBaseMaterials);
            workingRecord.choices.baseSceneWardMaterials = cell(1, nBaseMaterials);
            pwd
            for mm = 1:nBaseMaterials
                % use arbitrary but consistent reflectances
                if otherObjectReflectanceRandom
                    materialReflectanceNumber = randi(nOtherObjectSurfaceReflectance);
                else
                    materialReflectanceNumber = mm;
                end
                
                [~, ~, ~, matteMaterial, wardMaterial] = computeLuminance( ...
                    materialReflectanceNumber, [], workingRecord.hints);
                workingRecord.choices.baseSceneMatteMaterials{mm} = matteMaterial;
                workingRecord.choices.baseSceneWardMaterials{mm} = wardMaterial;
            end
            
            %% Assign a random illuminant to each light in the base scene.
            nBaseLights = numel(sceneData.lightIds);
            if (illuminantSpectrumNotFlat || nLightSpectra==1)
                whichLights = randi(nLightSpectra, [1, nBaseLights]);
            else
                whichLights = reflectanceNumber*ones([1, nBaseLights]);
            end            
            workingRecord.choices.baseSceneLights = lightSpectra(whichLights);
            
            %% Pick a light shape to insert.
            %   pack up the light in the format expected for Ward Land
            workingRecord.choices.insertedLights.names = shapeSet(randi(nShapes, 1));
            
            % Position of the illuminant
            if parser.Results.lightPositionRandom
                workingRecord.choices.insertedLights.positions = ...
                    {GetRandomPosition(sceneData.lightExcludeBox, sceneData.lightBox)};
            else
                % using fixed light position that works for the Library base scene
                workingRecord.choices.insertedLights.positions = ...
                    {[-6.504209 18.729564 5.017080]};                
            end
            
            % Size of the illuminant
            if parser.Results.lightScaleRandom
                workingRecord.choices.insertedLights.scales = {.5 + rand()};
            else
                workingRecord.choices.insertedLights.scales = {1};                
            end
            workingRecord.choices.insertedLights.rotations = {randi([0, 359], [1, 3])};                        
            workingRecord.choices.insertedLights.matteMaterialSets = {matteIlluminant};
            workingRecord.choices.insertedLights.wardMaterialSets = {wardIlluminant};
            if (illuminantSpectrumNotFlat || nLightSpectra==1)
                workingRecord.choices.insertedLights.lightSpectra = ...
                    lightSpectra(randi(nLightSpectra));
            else
                workingRecord.choices.insertedLights.lightSpectra = ...
                    lightSpectra(reflectanceNumber);                
            end                                    
            
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
                
                workingRecord.choices.insertedObjects.rotations{oo} = randi([0, 359], [1, 3]);
                
                if parser.Results.targetPositionRandom
                    workingRecord.choices.insertedObjects.positions{oo} = GetRandomPosition([0 0; 0 0; 0 0], sceneData.objectBox);
                else
                    % using fixed object position that works for the Library base scene
                    workingRecord.choices.insertedObjects.positions{oo} = [ -0.010709 4.927981 0.482899];
                end
                
                if parser.Results.targetScaleRandom
                    workingRecord.choices.insertedObjects.scales{oo} =  0.3 + rand()/2;
                else
                    workingRecord.choices.insertedObjects.scales{oo} =  0.5;
                end
                                
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
                targetLuminanceLevel, reflectanceNumber);
            
            [~, ~, ~, targetMatteMaterial, targetWardMaterial] = computeLuminanceByName( ...
                reflectanceFileName, targetLuminanceLevel, workingRecord.hints);
            
            % force the target object to use this computed reflectance
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
            workingRecord.recipe = BuildToyRecipe( ...
                defaultMappings, workingRecord.choices, {}, {}, lookAt, workingRecord.hints);
            
            %% Copy common resources into this recipe folder
            %
            % This just copies the illuminants, maybe should generalize for
            % other resources at some point.
            recipeResourceFolder = rtbWorkingFolder('folder','resources', 'hints', workingRecord.hints);
            copyfile(illuminantsFolder, recipeResourceFolder, 'f');
            
            %% Do a mask rendering, reject if target object is occluded.
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
            excludeFolders = {'scenes', 'renderings', 'images', 'temp'};
            workingRecord.recipe.input.sceneRecord = workingRecord;
            workingRecord.recipe.input.hints.whichConditions = [];
            rtbPackUpRecipe(workingRecord.recipe, archiveFile, 'ignoreFolders', excludeFolders);
        end
        
        sceneRecord(sceneIndex) = workingRecord;
        
    catch err
        SaveToyVirutalWorldError(originalFolder, err, workingRecord.recipe, workingRecord);
    end
end