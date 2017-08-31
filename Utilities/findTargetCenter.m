function [targetCenterR, targetCenterC] = findTargetCenter(isTarget)

% [targetCenterR, targetCenterC] = findTargetCenter(isTarget)
%
% Usage: 
%     [targetCenterR, targetCenterC] = findTargetCenter(isTarget);
%
% Description:
%   This functions find a pixel on the target object that would be used as
%   the center pixel for cropping the image. It first finds a bounding box 
%   around the target object. If the bounding box center pixel has all 
%   neighbors and next nearest neighbors on the target, then the bounding 
%   box center is chosen as the center for cropping. Otherwise, another
%   point on the target is selected at random such that its neighbors and 
%   next nearest neighbors are on the target.
%
% Input:
%   isTarget = a boolean matrix containg 1s for the target pixels.
%
% Output:
%   targetCenterR = row of center pixel
%   targetCenterC = col of center pixel
% 
% VS wrote this
%s
    centerPixelNN = 4;
    centerPixelArea = (2*centerPixelNN+1)^2;

    targetInds = find(isTarget) - 1;
    nRows = size(isTarget, 1);
    targetRows = 1 + mod(targetInds, nRows);
    targetCols = 1 + floor(targetInds / nRows);
    targetTop = min(targetRows);
    targetBottom = max(targetRows);
    targetLeft = min(targetCols);
    targetRight = max(targetCols);
    tempCenterR = targetTop + floor((targetBottom-targetTop)/2);
    tempCenterC = targetLeft + floor((targetRight-targetLeft)/2);

    if (sum(sum(isTarget(tempCenterR-centerPixelNN:tempCenterR+centerPixelNN,...
            tempCenterC-centerPixelNN:tempCenterC+centerPixelNN)))==centerPixelArea)
        targetCenterR = tempCenterR;
        targetCenterC = tempCenterC;
    else
        % find rank of each point on the target
        for ii = (centerPixelNN+1): (size(isTarget,1)-centerPixelNN)
            for jj = (centerPixelNN+1): (size(isTarget,2)-centerPixelNN)
                isTargetRank(ii,jj) = sum(sum(isTarget(ii-centerPixelNN:ii+centerPixelNN,...
                    jj-centerPixelNN:jj+centerPixelNN)));
            end
        end
        
        % find the points that have rank = centerPixelArea
        [row, col] = find(isTargetRank==centerPixelArea);
        
        % pick the ones that are closest to center
        distanceFromCenter = (row-tempCenterR).^2+(col-tempCenterC).^2;
%         [rowD, colD] = find(distanceFromCenter == min(distanceFromCenter));        
        [rowD, colD] = find(distanceFromCenter);        
        
        if (size(rowD,1)==0)
            targetCenterR = [];
            targetCenterC = [];
        else
            % choose one of these randomly
            indexChosen = rowD(randi(size(rowD,1)));

            % Assign it as the center point for cropping
            targetCenterR = row(indexChosen);
            targetCenterC = col(indexChosen);
        end
    end
        
end