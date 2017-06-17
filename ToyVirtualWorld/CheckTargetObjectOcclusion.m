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
% recipe = rtbExecuteRecipe(recipe);
% recipe = MakeToyRGBImages(recipe);

%% Check if we can see enough target pixels.
maskFilename = fullfile(recipe.input.hints.workingFolder, ...
    recipe.input.hints.recipeName,'renderings','Mitsuba','mask.mat');
targetMask = load(maskFilename);
isTarget = 0 < sum(targetMask.multispectralImage, 3);
targetPixelCount = sum(isTarget(:));

if ((targetPixelCount/totalBoundingBoxPixels < targetPixelThresholdMin || ...
    targetPixelCount/totalBoundingBoxPixels > targetPixelThresholdMax))
    
    rejected =1;
    fprintf('target pixels %d -> rejected %d\n',targetPixelCount ,rejected);
else
    [targetCenterR, targetCenterC] = findTargetCenter(isTarget);
    if isempty((isTarget(targetCenterR,targetCenterC)))
        rejected = 1;
    else
        rejected =  ~(isTarget(targetCenterR,targetCenterC)) ;
    end
    fprintf('target pixels %d, center pixel %d -> rejected %d\n', ...
    targetPixelCount , isTarget(targetCenterR,targetCenterC),rejected);
end
    