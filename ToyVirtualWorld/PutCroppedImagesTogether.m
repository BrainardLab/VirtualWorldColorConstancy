function PutCroppedImagesTogether(varargin)
% PutCroppedImagesTogether('outputName','FixedTargetShapeFixedIlluminantFixedBkGnd')
%
% USAGE: This function makes a struct with fields multispectralImages,
%   lightnessLevels, reflectanceNumbers and some other filename informations
%   about the images for a particular case and saves the struct as a .mat
%   file in the parent directory provided in the input field 'outputname'.
% Input:
%    outputName     : Name of base folder that contains the stimuli
%    luminanceLevels: The luminance levels to make the struct
%    reflectanceNumbers : Reflectance number of the image files
%

% Oct 16 2017, VS wrote this

%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('outputName','ExampleOutput',@ischar);
parser.addParameter('luminanceLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', [1 2], @isnumeric);
parser.addParameter('cropImageHalfSize', 25, @isnumeric);
parser.addParameter('shapeSet', '\w+', @ischar);
parser.addParameter('baseSceneSet', '\w+', @ischar);
parser.parse(varargin{:});

luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;
cropImageHalfSize = parser.Results.cropImageHalfSize;
shapeSet = parser.Results.shapeSet;
baseSceneSet = parser.Results.baseSceneSet;

%% Overall Setup.

% location of packed-up recipes
projectName = 'VirtualWorldColorConstancy';
recipeFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName, 'Originals');
if ~exist(recipeFolder, 'dir')
    disp(['Recipe folder not found: ' recipeFolder]);
end

% % location of reflectance folder
% pathToTargetReflectanceFolder = fullfile(getpref(projectName, 'baseFolder'),...
%     parser.Results.outputName,'Data','Reflectances','TargetObjects');

% edit some batch renderer options
hints.workingFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Working');

%% Assemble recipies by combinations of target luminances reflectances.
nReflectances = length(reflectanceNumbers);
nLuminanceLevels = length(luminanceLevels);
nScenes = nLuminanceLevels * nReflectances;
sceneRecord = struct( ...
    'targetLuminanceLevel', [], ...
    'reflectanceNumber', []);

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

% Outputs for AMA
S = struct(...
    'multispectralImage',zeros(31,(2*cropImageHalfSize+1)^2,nScenes),...
    'luminanceLevels', zeros(1,nScenes),...
    'reflectanceNumber', zeros(1,nScenes),...
    'cropImageSize',2*cropImageHalfSize+1,...
    'wavelengths',[400 10 31]);

recipeName = FormatRecipeName(targetLuminanceLevel(1), reflectanceNumber(1), ...
    shapeSet, baseSceneSet);
recipePattern = fullfile(recipeName,'ConeResponse.mat');
pathToRecipe = rtbFindFiles('root', hints.workingFolder, 'filter', recipePattern);
tempRecipe = parloadConeResponse(pathToRecipe{1});

S.fullImageHeight = tempRecipe.input.hints.imageHeight;
S.fullImageWidth = tempRecipe.input.hints.imageWidth;

parfor ii = 1:nScenes
    workingRecord = sceneRecord(ii);
    targetLuminanceLevel = workingRecord.targetLuminanceLevel;
    tempReflectanceNumber = workingRecord.reflectanceNumber;
    
        try
    % get the recipe
    recipeName = FormatRecipeName(targetLuminanceLevel, tempReflectanceNumber, ...
        shapeSet, baseSceneSet);
    recipePattern = fullfile(recipeName,'ConeResponse.mat');
    pathToRecipe = rtbFindFiles('root', hints.workingFolder, 'filter', recipePattern);
    recipe = parloadConeResponse(pathToRecipe{1});
    luminanceLevels(ii) = recipe.input.sceneRecord.targetLuminanceLevel;
    reflectanceNumber(ii) = recipe.input.sceneRecord.reflectanceNumber;
    multispectralImage(:,:,ii) = ImageToCalFormat(recipe.processing.croppedImage);
    pathToFullImage{ii} = recipe.rendering.radianceDataFiles{2};
        catch err
            SaveToyVirutalWorldError(analysedFolder, err, recipe, varargin);
        end
    
end
S.luminanceLevels = round(luminanceLevels*10000)/10000;
S.reflectanceNumber = reflectanceNumber;
S.multispectralImage = multispectralImage;
S.baseFolderName = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName);
S.pathToFullMultispectralImage = pathToFullImage;

save(fullfile(getpref(projectName, 'baseFolder'),...
    parser.Results.outputName,'croppedMultiSpectralStimulus.mat'),...
    'S','-v7.3');
