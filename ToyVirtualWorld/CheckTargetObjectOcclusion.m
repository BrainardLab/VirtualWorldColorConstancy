function rejected = CheckTargetObjectOcclusion(recipe, varargin)
%% Check whether the Toy Virtual World target object was occluded.
%
% rejected = CheckTargetObjectOcclusion(recipe) checks the given recipe to
% determine whether the target object was occluded by another object.
%
% This is based on the toy virutal world "mask" rendering condition.  So
% this condition will be executed.
%
%
%
% Usage:
%   rejected = CheckTargetObjectOcclusion(recipe, varargin)
%

parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.addParameter('imageWidth', 320, @isnumeric);
parser.addParameter('imageHeight', 240, @isnumeric);
parser.addParameter('targetPixelThreshold', 30, @isnumeric);
parser.parse(recipe, varargin{:});
recipe = parser.Results.recipe;
imageWidth = parser.Results.imageWidth;
imageHeight = parser.Results.imageHeight;
targetPixelThreshold = parser.Results.targetPixelThreshold;

%% Do some rendering and analysis.
recipe.input.hints.renderer = 'Mitsuba';
recipe.input.hints.imageWidth = imageWidth;
recipe.input.hints.imageHeight = imageHeight;
recipe.input.hints.whichConditions = 2;
recipe = ExecuteRecipe(recipe);
recipe = MakeToyRGBImages(recipe);

%% Check if we can see enough target pixels.
targetMask = LoadRecipeProcessingImageFile(recipe, 'radiance', 'mask');
isTarget = 0 < sum(targetMask, 3);
targetPixelCount = sum(isTarget(:));
rejected = targetPixelCount < targetPixelThreshold;

fprintf('target pixels %d/%d -> rejected %d\n', ...
    targetPixelCount, targetPixelThreshold, rejected);
