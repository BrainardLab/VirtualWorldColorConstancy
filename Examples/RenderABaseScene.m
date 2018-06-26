function RenderABaseScene(varargin)
%% Render a base scene without any target object.
%
% Key/value pairs
%   'outputName' - Output File Name, Default ExampleOutput
%   'imageWidth' - image width, Should be kept small to keep redering time
%                   low for rejected recipes
%   'imageHeight'- image height, Should be kept small to keep redering time
%                   low for rejected recipes
%   'nOtherObjectSurfaceReflectance' - Number of spectra to be generated
%                   for choosing background surface reflectance (max 999)
%   'maxAttempts' - maximum number of attempts to find the right recipe
%   'minMeanIlluminantLevel' - Min of mean value of ilumination spectrum
%   'maxMeanIlluminantLevel' - Max of mean value of ilumination spectrum
%   'illuminantScaling' - Boolean to specify if the mean value of the
%                         illuminant spectra should be scaled or not.
%                         0 -> No scaling. The spectra varies only in shape
%                         1 -> The mean value is chosen randomly with
%                         logarithmic spacing in the range
%                         [minMeanIlluminantLevel maxMeanIlluminantLevel]
%   'baseSceneSet'  - Base scenes to be used for renderings. One of these
%                  base scenes is used for each rendering

%% Want each run to start with its own random seed
rng('shuffle');

%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('outputName','ExampleOutput',@ischar);
parser.addParameter('imageWidth', 320, @isnumeric);
parser.addParameter('imageHeight', 240, @isnumeric);
parser.addParameter('nOtherObjectSurfaceReflectance', 100, @isnumeric);
parser.addParameter('maxAttempts', 30, @isnumeric);
parser.addParameter('minMeanIlluminantLevel', 10, @isnumeric);
parser.addParameter('maxMeanIlluminantLevel', 30, @isnumeric);
parser.addParameter('illuminantScaling', 0, @isnumeric);
parser.addParameter('baseSceneSet', ...
    {'CheckerBoard', 'IndoorPlant', 'Library', 'Mill', 'TableChairs', 'Warehouse'}, @iscellstr);
parser.addParameter('maxDepth', 10, @isnumeric);

parser.parse(varargin{:});
imageWidth = parser.Results.imageWidth;
imageHeight = parser.Results.imageHeight;
nOtherObjectSurfaceReflectance = parser.Results.nOtherObjectSurfaceReflectance;
maxAttempts = parser.Results.maxAttempts;
baseSceneSet = parser.Results.baseSceneSet;
maxDepth = parser.Results.maxDepth;

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

%% Set the size of the image

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

%% Make some illuminants and store them in the Data/Illuminants/BaseScene folder.
dataBaseDir = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Data');
illuminantsFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Data','Illuminants','BaseScene');
totalRandomLightSpectra = 999;
makeIlluminants(totalRandomLightSpectra,illuminantsFolder, 0);

%% Make some reflectances and store them where they want to be
otherObjectFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Data','Reflectances','OtherObjects');
makeOtherObjectReflectance(nOtherObjectSurfaceReflectance,otherObjectFolder);

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

%% Predefine scalings for the illuminants in each scene
% If the iluminants are scaled to match the variations in the mean value of
% the spectra to natural scenes, we have decided to scale all the spectra
% in the base scene with the same scale factor. This is chosen here.
if parser.Results.illuminantScaling
    if illuminantSpectraRandom
        % Scales sampled from true Granda mean value distribution
        % scales = generateIlluminantsScalesForScene(nLuminanceLevels * nReflectances);
        
        % Scales sampled uniformaly over Granda mean value range
        scales = generateLogUniformScales(1, ...
            parser.Results.maxMeanIlluminantLevel, parser.Results.minMeanIlluminantLevel);
    else
        scales = generateLogUniformScales(1, parser.Results.maxMeanIlluminantLevel, ...
            parser.Results.minMeanIlluminantLevel)*ones(1,nLuminanceLevels * nReflectances);
    end
else
    scales = 1;
end

%% Assemble recipies by combinations of target luminances reflectances.
nScenes = 1;
sceneRecord = struct('nAttempts', cell(1, nScenes), ...
    'choices', [], ...
    'hints', hints, ...
    'rejected', [], ...
    'recipe', [], ...
    'styles', []);

sceneRecord(1).scales = scales(1);

for sceneIndex = 1
    workingRecord = sceneRecord(sceneIndex);
    
    try
        for attempt = 1:maxAttempts
            
            %% Pick the base scene randomly.
            bIndex = randi(size(baseSceneSet, 2), 1);
            
            sceneInfo = baseSceneInfos{bIndex};
            workingRecord.choices.baseSceneName = sceneInfo.name;
            sceneData = baseScenes{bIndex}.copy('name', workingRecord.choices.baseSceneName);
            
            %% Choose a unique name for this recipe.
            recipeName = workingRecord.choices.baseSceneName;
            workingRecord.hints.recipeName = recipeName;
            
            %% Position the camera.
            %   "eye" position is from the first camera "slot"
            %   "target" position is the target object's position
            %   "up" direction is from the first camera "slot"
            targetPosition = GetRandomPosition([0 0; 0 0; 0 0], sceneInfo.objectBox);
            eye = sceneInfo.cameraSlots(1).position;
            up = sceneInfo.cameraSlots(1).up;
            lookAt = mexximpLookAt(eye, targetPosition, up);
            
            cameraName = sceneData.model.cameras(1).name;
            isCameraNode = strcmp(cameraName, {sceneData.model.rootNode.children.name});
            sceneData.model.rootNode.children(isCameraNode).transformation = lookAt;
            
            %% Choose styles for the full radiance rendering.
            fullRendering = VwccMitsubaRenderingQuality( ...
                'integratorPluginType', 'path', ...
                'samplerPluginType', 'ldsampler');
            fullRendering.addIntegratorProperty('maxDepth', 'integer', maxDepth);
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
            
            % assign spectra to lights
            areaLightSpectra = VseMitsubaEmitterSpectra( ...
                'name', 'areaLightSpectra', ...
                'pluginType', 'area', ...
                'propertyName', 'radiance');
            %areaLightSpectra.spectra = emitterSpectra;
            
            % If scaling =1, scale all the illuminant spectra in the
            % base scene by the same scale factor. To do this the
            % pre-selected illuminants are rewritten in the resource
            % folder of the recipe with the scaling and the paths are
            % appropiately changed.
            
            tempIlluminantIndex = randperm(length(illuminantSpectra),nBaseLights);
            for iterTempIlluminantIndex = 1:length(tempIlluminantIndex)
                tempSpectrumFileName = fullfile(dataBaseDir,'Illuminants','BaseScene',...
                    illuminantSpectra(tempIlluminantIndex(iterTempIlluminantIndex)));
                [tempWavelengths, tempMagnitudes] = rtbReadSpectrum(tempSpectrumFileName{1});
                resourceFolder = fullfile(workingRecord.hints.workingFolder,recipeName,'resources');
                tempFileName = fullfile(resourceFolder,'Illuminants','BaseScene',...
                    illuminantSpectra(tempIlluminantIndex(iterTempIlluminantIndex)));
                rtbWriteSpectrumFile(tempWavelengths,workingRecord.scales*tempMagnitudes,tempFileName{1});
            end
            tempIlluminantSpectra = illuminantSpectra(tempIlluminantIndex);
            areaLightSpectra.resourceFolder = resourceFolder;
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
            tempBaseSceneReflectances = baseSceneReflectances((randperm(length(baseSceneReflectances))));
            baseSceneDiffuse.addManySpectra(tempBaseSceneReflectances);
            
            workingRecord.styles.normal = {fullRendering, ...
                blessBaseLights, areaLightSpectra, baseSceneDiffuse};
            
            %% Do the final rendering
            innerModels = [];
            workingRecord.recipe = vseBuildRecipe(sceneData, innerModels, workingRecord.styles, 'hints', workingRecord.hints);
            
            
            % generate scene files and render
            workingRecord.recipe = rtbExecuteRecipe(workingRecord.recipe);
            
            % move on to save this recipe
            break;
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
