%% Convert recipe multi-spectral renderings to sRGB representations.
%   @param recipe a recipe from BuildWardLandRecipe()
%   @param toneMapFactor passed to MakeMontage()
%   @param isScale passed to MakeMontage()
%
% @details
% Processes several Toy multi-spectral renderings and makes sRGB
% representations of them.  @a toneMapFactor and @a isScale affect scaling
% of the sRGB images.  See MultispectralToSRGB() and XYZToSRGB().
%
% @details
% Saves sRGB images in the "radiance" processing group.  See
% SaveRecipeProcessingImageFile().
%
% @details
% Usage:
%   recipe = MakeToyRGBImages(recipe, toneMapFactor, isScale)
%
% @ingroup WardLand
function recipe = MakeToyRGBImages(recipe, toneMapFactor, isScale)

if nargin < 2 || isempty(toneMapFactor)
    toneMapFactor = 100;
end

if nargin < 3 || isempty(isScale)
    isScale = true;
end

%% Load scene renderings.
nRenderings = numel(recipe.rendering.radianceDataFiles);
maskDataFiles = {};
for ii = 1:nRenderings
    dataFile = recipe.rendering.radianceDataFiles{ii};
    if ~isempty(strfind(dataFile, 'normal.mat'))
        normalDataFile = dataFile;
    elseif ~isempty(strfind(dataFile, 'mask.mat'))
        maskDataFile = dataFile;
    end
end

%% Get multi-spectral and sRGB radiance images.
normalRendering = load(normalDataFile);
normalRadiance = normalRendering.multispectralImage;

maskRendering = load(maskDataFile);
maskRadiance = maskRendering.multispectralImage;

S = normalRendering.S;
[normalSrgb, normalXyz] = toRgbAndXyz(normalRadiance, S, toneMapFactor, isScale);
[maskSrgb, maskXyz] = toRgbAndXyz(maskRadiance, S, toneMapFactor, isScale);

%% Save images to disk.
group = 'radiance';
format = 'png';
recipe = SaveRecipeProcessingImageFile(recipe, group, 'normalSrgb', format, normalSrgb);
recipe = SaveRecipeProcessingImageFile(recipe, group, 'maskSrgb', format, maskSrgb);

format = 'mat';
recipe = SaveRecipeProcessingImageFile(recipe, group, 'normalXyz', format, normalXyz);
recipe = SaveRecipeProcessingImageFile(recipe, group, 'maskXyz', format, maskXyz);

recipe = SetRecipeProcessingData(recipe, group, 'S', S);
recipe = SaveRecipeProcessingImageFile(recipe, group, 'normal', 'mat', normalRadiance);
recipe = SaveRecipeProcessingImageFile(recipe, group, 'mask', 'mat', maskRadiance);


%% Get uint8 versions of sRGB and XYZ images.
function [srgbUint, xyz] = toRgbAndXyz(radiance, S, toneMapFactor, isScale)
[srgb, xyz] = MultispectralToSRGB(radiance, S, toneMapFactor, isScale);
srgbUint = uint8(srgb);
