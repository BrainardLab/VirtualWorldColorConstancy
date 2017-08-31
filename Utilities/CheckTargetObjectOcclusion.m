function rejected = CheckTargetObjectOcclusion(recipe, varargin)
% rejected = CheckTargetObjectOcclusion(recipe, varargin)
%
% Usage: 
%     rejected = CheckTargetObjectOcclusion(workingRecord.recipe, ...
%                 'imageWidth', 320, ...
%                 'imageHeight', 240, ...
%                 'targetPixelThresholdMin', 0.1, ...
%                 'targetPixelThresholdMax', 0.6, ...
%                 'totalBoundingBoxPixels', 51*51);
%
% Description:
%     This function checks whether the target object was occluded. The
%     function counts the number of pixels in the cropped region that
%     belong to the target. It this number is between a specfied range of
%     the cropped image the functions returns a 0, otherwise it returns 1.
%
% Input:
%   recipe = recipe containg the multispectral image and the mask image
%   imageWidth = width of image
%   imageHeight = height of image
%   targetPixelThresholdMin = min fraction of visible target in cropped part
%   targetPixelThresholdMax = max fraction of visible target in cropped part
%   totalBoundingBoxPixels = total number of pixels in cropped part
%   maskFileName = name of mask file
%
% Output:
%   rejected = boolean showing whether target is occluded or not. 
%               1 = occluded, 0 = not occluded
%
% VS wrote this
%
parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.addParameter('imageWidth', 320, @isnumeric);
parser.addParameter('imageHeight', 240, @isnumeric);
% parser.addParameter('targetPixelThreshold', 30, @isnumeric);
parser.addParameter('targetPixelThresholdMin', 0.2, @isnumeric);
parser.addParameter('targetPixelThresholdMax', 0.8, @isnumeric);
parser.addParameter('totalBoundingBoxPixels', 2601, @isnumeric);
parser.addParameter('maskFileName','mask.mat',@ischar);
parser.parse(recipe, varargin{:});
recipe = parser.Results.recipe;
imageWidth = parser.Results.imageWidth;
imageHeight = parser.Results.imageHeight;
% targetPixelThreshold = parser.Results.targetPixelThreshold;
targetPixelThresholdMin = parser.Results.targetPixelThresholdMin;
targetPixelThresholdMax = parser.Results.targetPixelThresholdMax;
totalBoundingBoxPixels = parser.Results.totalBoundingBoxPixels;
maskFileName = parser.Results.maskFileName;


%% Do some rendering and analysis.
recipe.input.hints.renderer = 'Mitsuba';
recipe.input.hints.imageWidth = imageWidth;
recipe.input.hints.imageHeight = imageHeight;
recipe.input.hints.whichConditions = 2;
% recipe = rtbExecuteRecipe(recipe);
% recipe = MakeToyRGBImages(recipe);

%% Check if we can see enough target pixels.
maskFilename = fullfile(recipe.input.hints.workingFolder, ...
    recipe.input.hints.recipeName,'renderings','Mitsuba',maskFileName);
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
    