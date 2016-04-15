%% Analyze Virtual Scene renderings for shape index factoids.
%   @param recipe a recipe struct from BuildToyRecipe()
%
% @details
% Uses the "normal" scene file for the given Toy @a recipe to
% compute an object pixel mask, based on Mitsuba's "shapeIndex" factoid.
%
% @details
% Returns the given @a recipe, updated with object pixel masks data saved
% in the "shapes" group.
%
% @details
% Usage:
%   recipe = MakeToyShapeIndexFactoidImages(recipe)
%
% @ingroup WardLand
function recipe = MakeToyShapeIndexFactoidImages(recipe)

%% Get the "normal" scene file.
nScenes = numel(recipe.rendering.scenes);
for ii = 1:nScenes
    scene = recipe.rendering.scenes{ii};
    if strcmp('normal', scene.imageName)
        normalSceneFile = GetWorkingAbsolutePath(scene.mitsubaFile, recipe.input.hints);
    end
end

%% Invoke Mitsuba for the "shapeIndex" factoid.
mitsuba = getpref('MitsubaRGB');

factoids = {'shapeIndex'};
format = 'rgb';

% invoke once with "single sampling" to get an answer in every pixel
singleSampling = true;
[~, ~, ~, ~, factoidOutput] = ...
    RenderMitsubaFactoids(normalSceneFile, [], [], [], ...
    factoids, format, recipe.input.hints, mitsuba, singleSampling);
shapeIndexes = factoidOutput.shapeIndex.data(:,:,1);

%% Determine object masks and coverage.
isGood = mod(shapeIndexes, 1) == 0;
shapeIndexMask = 1 + shapeIndexes;
shapeIndexMask(~isGood) = 0;

%% Give each shape a color.
nShapes = max(shapeIndexMask(:));
mutedColors = 128 * parula(nShapes) + 64;
colorMap = [0 0 0; mutedColors];

% if we can, highlight the target object
targetMask = LoadRecipeProcessingImageFile(recipe, 'radiance', 'mask');
if ~isempty(targetMask)
    isTarget = 0 < sum(targetMask, 3);
    candidateIndexes = shapeIndexMask(isTarget);
    targetShapeIndex = mode(candidateIndexes);
    
    % color in the target shape
    colorMap(1 + targetShapeIndex, :) = [255 0 0];
    
    % find the bounding box about the shape
    targetInds = find(isTarget) - 1;
    nRows = size(isTarget, 1);
    targetRows = 1 + mod(targetInds, nRows);
    targetCols = 1 + floor(targetInds / nRows);
    targetTop = min(targetRows);
    targetBottom = max(targetRows);
    targetLeft = min(targetCols);
    targetRight = max(targetCols);
    
    % color in the bounding box like the target shape
    shapeIndexMask(targetTop, targetLeft:targetRight) = targetShapeIndex;
    shapeIndexMask(targetBottom, targetLeft:targetRight) = targetShapeIndex;
    shapeIndexMask(targetTop:targetBottom, targetLeft) = targetShapeIndex;
    shapeIndexMask(targetTop:targetBottom, targetRight) = targetShapeIndex;
    
    % remember what we found
    recipe.processing.target.shapeIndex = targetShapeIndex;
    recipe.processing.target.top = targetTop;
    recipe.processing.target.bottom = targetBottom;
    recipe.processing.target.left = targetLeft;
    recipe.processing.target.right = targetRight;
end

shapeColors = zeros(recipe.input.hints.imageHeight, recipe.input.hints.imageWidth, 3, 'uint8');
shapeColors(:) = colorMap(1 + shapeIndexMask, :);

%% Save mask images.
group = 'shapes';
recipe = SaveRecipeProcessingImageFile(recipe, group, 'shapeIndexes', 'mat', shapeIndexMask);
recipe = SaveRecipeProcessingImageFile(recipe, group, 'shapeColors', 'png', shapeColors);
