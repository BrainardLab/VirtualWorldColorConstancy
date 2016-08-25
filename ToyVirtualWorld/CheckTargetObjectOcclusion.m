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
% parser.addParameter('targetPixelThreshold', 30, @isnumeric);
parser.addParameter('targetPixelThresholdMin', 0.2, @isnumeric);
parser.addParameter('targetPixelThresholdMax', 0.8, @isnumeric);
parser.addParameter('totalBoundingBoxPixels', 2601, @isnumeric);
parser.parse(recipe, varargin{:});
recipe = parser.Results.recipe;
imageWidth = parser.Results.imageWidth;
imageHeight = parser.Results.imageHeight;
% targetPixelThreshold = parser.Results.targetPixelThreshold;
targetPixelThresholdMin = parser.Results.targetPixelThresholdMin;
targetPixelThresholdMax = parser.Results.targetPixelThresholdMax;
totalBoundingBoxPixels = parser.Results.totalBoundingBoxPixels;


%% Do some rendering and analysis.
recipe.input.hints.renderer = 'Mitsuba';
recipe.input.hints.imageWidth = imageWidth;
recipe.input.hints.imageHeight = imageHeight;
recipe.input.hints.whichConditions = 2;
recipe = rtbExecuteRecipe(recipe);
recipe = MakeToyRGBImages(recipe);

%% Check if we can see enough target pixels.
targetMask = LoadRecipeProcessingImageFile(recipe, 'radiance', 'mask');
isTarget = 0 < sum(targetMask, 3);
targetPixelCount = sum(isTarget(:));

targetInds = find(isTarget) - 1;
    nRows = size(isTarget, 1);
    targetRows = 1 + mod(targetInds, nRows);
    targetCols = 1 + floor(targetInds / nRows);
    targetTop = min(targetRows);
    targetBottom = max(targetRows);
    targetLeft = min(targetCols);
    targetRight = max(targetCols);
    targetCenterR = targetTop + floor((targetBottom-targetTop)/2);
    targetCenterC = targetLeft + floor((targetRight-targetLeft)/2);
    
rejected = ( (targetPixelCount/totalBoundingBoxPixels < targetPixelThresholdMin || ...
    targetPixelCount/totalBoundingBoxPixels > targetPixelThresholdMax) ...
    || ~(isTarget(targetCenterR,targetCenterC)) );
    
fprintf('target pixels %d, %d -> rejected %d\n', ...
    targetPixelCount , isTarget(targetCenterR,targetCenterC),rejected);