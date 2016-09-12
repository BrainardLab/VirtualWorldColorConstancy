function [targetCenterR, targetCenterC] = findTargetCenter(isTarget)

% finds the center pixels for croping the image. If the bounding box center
% pixel has all neighbors and nearest neighbors on the target, then the
% center is chosen. Otherwise, the center 


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

    if (sum(sum(isTarget(tempCenterR-2:tempCenterR+2,tempCenterC-2:tempCenterC+2)))==25)
        targetCenterR = tempCenterR;
        targetCenterC = tempCenterC;
    else
        % find rank of each point on the target
        for ii = 3: (size(isTarget,1)-2)
            for jj = 3: (size(isTarget,2)-2)
                isTargetRank(ii,jj) = sum(sum(isTarget(ii-2:ii+2,jj-2:jj+2)));
            end
        end
        
        % find the points that have rank = 25
        [row, col] = find(isTargetRank==25);
        row = unique(row);
        col = unique(col);
        targetCenterR = row(find((row-tempCenterR)==min(abs(row-tempCenterR))));
        targetCenterC = col(find((col-tempCenterC)==min(abs(col-tempCenterC))));
    end
        
end