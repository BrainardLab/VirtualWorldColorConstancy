%% Convert recipe multi-spectral renderings to sRGB representations.
%   @param recipe a recipe from BuildToyRecipe()
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

recipe = makeNamedImages(recipe, 'mask', toneMapFactor, isScale);
recipe = makeNamedImages(recipe, 'normal', toneMapFactor, isScale);


%% Make RGBZ images based on a named rendering.
function recipe = makeNamedImages(recipe, name, toneMapFactor, isScale)
% load the rendering
nRenderings = numel(recipe.rendering.radianceDataFiles);
namedDataFile = [];
for ii = 1:nRenderings
    dataFile = recipe.rendering.radianceDataFiles{ii};
    if ~isempty(strfind(dataFile, [name '.mat']))
        namedDataFile = dataFile;
    end
end

if isempty(namedDataFile)
    return;
end

% get multi-spectral and sRGB radiance images
namedRendering = load(namedDataFile);
namedRadiance = namedRendering.multispectralImage;

S = namedRendering.S;
[normalSrgb, normalXyz] = toRgbAndXyz(namedRadiance, S, toneMapFactor, isScale);

% save images to disk
group = 'radiance';
recipe = SaveRecipeProcessingImageFile(recipe, group, [name 'Srgb'], 'png', normalSrgb);
recipe = SaveRecipeProcessingImageFile(recipe, group, [name 'Xyz'], 'mat', normalXyz);
recipe = SetRecipeProcessingData(recipe, group, 'S', S);
recipe = SaveRecipeProcessingImageFile(recipe, group, name, 'mat', namedRadiance);


%% Get uint8 versions of sRGB and XYZ images.
function [srgbUint, xyz] = toRgbAndXyz(radiance, S, toneMapFactor, isScale)
[srgb, xyz] = rtbMultispectralToSRGB(radiance, S, 'toneMapFactor', toneMapFactor, 'isScale', isScale);
srgbUint = uint8(srgb);
