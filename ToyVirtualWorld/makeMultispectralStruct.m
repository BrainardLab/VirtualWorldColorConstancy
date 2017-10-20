function makeMultispectralStruct(varargin)
%%makeMultispectralStruct Make the struct with cropped multispctral images
%
% Usage:
%   makeMultispectralStruct('outputName','FixedTargetShapeFixedIlluminantFixedBkGnd')
%
% Description: 
%   This function makes a struct with fields multispectralImages,
%   lightnessLevels, reflectanceNumbers, uniqueLuminanceLevels, ctgInd,
%   cropSize, wavelengths, fullImageHeight, fullImageWidth, baseFolderName,
%   and pathToFullMultispectralimage. The struct is saved as a .mat
%   file in the parent directory provided in the input field 'outputname'.
%
% Input:
%    outputName     : Name of base folder that contains the stimuli
%    luminanceLevels: The luminance levels to make the struct
%    reflectanceNumbers : Reflectance number of the image files
%
% Output:
%
% Optional key/value pairs:
%    'luminanceLevels' : (numerical vector) Luminance levels of images to be selected for struct (defalult [0.2 0.6])
%    'reflectanceNumbers' : (scalar) reflectnace numbers to be used for struct (default [1 2])
%    'cropImageHalfSize : (integer) Size of cropped image (default 25)
%    'shapeSet': Name of target object shape (default '\w+')
%    'baseSceneSet': Name of baseScene (default '\w+')

% Oct 16 2017, VS wrote this

%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('outputName','ExampleOutput',@ischar);
parser.addParameter('luminanceLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', [1 2], @isnumeric);
parser.addParameter('cropImageHalfSize', 25, @isnumeric);
parser.addParameter('shape', '\w+', @ischar);
parser.addParameter('baseScene', '\w+', @ischar);
parser.parse(varargin{:});

luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;
cropImageHalfSize = parser.Results.cropImageHalfSize;
shape = parser.Results.shape;
baseScene = parser.Results.baseScene;

%% Overall Setup.
smallNumber = 10^(-4);
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
    'uniqueLuminanceLevels', [],...
    'ctgInd', zeros(1,nScenes),...
    'cropImageSize',2*cropImageHalfSize+1,...
    'wavelengths',[400 10 31]);

recipeName = FormatRecipeName(targetLuminanceLevel(1), reflectanceNumber(1), ...
    shape, baseScene);
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
        shape, baseScene);
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
S.uniqueLuminanceLevels = unique(S.luminanceLevels);
for ii = 1:10
    S.ctgInd(abs(S.luminanceLevels-S.uniqueLuminanceLevels(ii)) < smallNumber) = ii;
end
S.reflectanceNumber = reflectanceNumber;
S.multispectralImage = multispectralImage;
S.baseFolderName = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName);
S.pathToFullMultispectralImage = pathToFullImage;

save(fullfile(getpref(projectName, 'baseFolder'),...
    parser.Results.outputName,'multispectralStruct.mat'),...
    'S','-v7.3');
