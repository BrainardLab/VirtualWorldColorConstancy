%% Compute the "albedo" factoid images for a WardLand recipe.
%   @param recipe a recipe struct from BuildToyRecipe()
%   @param toneMapFactor passed to MakeMontage()
%   @param isScale passed to MakeMontage()
%
% @details
% Uses Mitsuba and results from MakeRecipeSceneFiles() to compute the
% "albedo" factoid for the "normal" and "mask" conditions in the given Toy
% Virtual World @a recipe.
%
% @details
% Returns the given @a recipe, updated with albedo image data saved
% in the "albedo" and "reflectance" groups.
%
% @details
% Usage:
%   recipe = MakeToyAlbedoFactoidImages(recipe, toneMapFactor, isScale)
%
% @ingroup WardLand
function recipe = MakeToyAlbedoFactoidImages(recipe, toneMapFactor, isScale)

if nargin < 2 || isempty(toneMapFactor)
    toneMapFactor = 100;
end

if nargin < 3 || isempty(isScale)
    isScale = true;
end

%% Get the "normal" and "mask" scene files.
nScenes = numel(recipe.rendering.scenes);
for ii = 1:nScenes
    scene = recipe.rendering.scenes{ii}.scene;
    if strcmp('normal', scene.imageName)
        normalSceneFile = rtbWorkingAbsolutePath(scene.mitsubaFile, 'hints', recipe.input.hints);
    elseif strcmp('mask', scene.imageName)
        maskSceneFile = rtbWorkingAbsolutePath(scene.mitsubaFile, 'hints', recipe.input.hints);
    end
end

%% Invoke Mitsuba for the "albedo" factoid.
mitsuba = getpref('Mitsuba');
factoids = {'albedo'};

% the normal rendering
[~, ~, ~, ~, normalFactoids] = ...
    RenderMitsubaFactoids(normalSceneFile, [], [], [], ...
    factoids, 'spectrum', recipe.input.hints, mitsuba);
[~, S, order] = rtbWlsFromSliceNames(normalFactoids.albedo.channels);
normalAlbedo = normalFactoids.albedo.data(:,:,order);

% the mask rendering
[~, ~, ~, ~, maskFactoids] = ...
    RenderMitsubaFactoids(maskSceneFile, [], [], [], ...
    factoids, 'spectrum', recipe.input.hints, mitsuba);
[~, ~, order] = rtbWlsFromSliceNames(maskFactoids.albedo.channels);
maskAlbedo = maskFactoids.albedo.data(:,:,order);


%% Make sRGB representations.
normalAlbedoSrgb = uint8(MultispectralToSRGB(normalAlbedo, S, toneMapFactor, isScale));
maskAlbedoSrgb = uint8(MultispectralToSRGB(maskAlbedo, S, toneMapFactor, isScale));

%% Save images.
group = 'albedo';
format = 'mat';
recipe = SaveRecipeProcessingImageFile(recipe, group, 'normalAlbedo', format, normalAlbedo);
recipe = SaveRecipeProcessingImageFile(recipe, group, 'maskAlbedo', format, maskAlbedo);

format = 'png';
recipe = SaveRecipeProcessingImageFile(recipe, group, 'normalAlbedoSrgb', format, normalAlbedoSrgb);
recipe = SaveRecipeProcessingImageFile(recipe, group, 'maskAlbedoSrgb', format, maskAlbedoSrgb);

