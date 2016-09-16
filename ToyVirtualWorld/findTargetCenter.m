function [targetCenterR, targetCenterC] = findTargetCenter(isTarget)

% finds the center pixels for croping the image. If the bounding box center
% pixel has all neighbors and nearest neighbors on the target, then the
% center is chosen. Otherwise, the center 
    
    centerPixelNN = 5;
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

    if (sum(sum(isTarget(tempCenterR-2:tempCenterR+2,tempCenterC-2:tempCenterC+2)))==centerPixelArea)
        targetCenterR = tempCenterR;
        targetCenterC = tempCenterC;
    else
        % find rank of each point on the target
        for ii = 3: (size(isTarget,1)-2)
            for jj = 3: (size(isTarget,2)-2)
                isTargetRank(ii,jj) = sum(sum(isTarget(ii-2:ii+2,jj-2:jj+2)));
            end
        end
        
        % find the points that have rank = centerPixelArea
        [row, col] = find(isTargetRank==centerPixelArea);
        
        % pick the ones that are closest to center
        distanceFromCenter = (row-tempCenterR).^2+(col-tempCenterC).^2;
%         [rowD, colD] = find(distanceFromCenter==min(distanceFromCenter));        
        [rowD, colD] = find(distanceFromCenter);        
        
        % choose one of these randomly
        indexChosen = rowD(randi(size(rowD)));

        % Assign it as the center point for cropping
        targetCenterR = row(indexChosen);
        targetCenterC = col(indexChosen);
    end
        
end