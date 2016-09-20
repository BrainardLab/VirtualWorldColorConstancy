function [ averageResponse ] = averageAnnularConeResponseDemosaic(nAnnularRegions, coneResponseDemosaic)
% This function calcuates the LMS cone responses in concentric annular
% regions wiht the center at the center pixel of the cone mosaic.

    averageResponse=zeros(nAnnularRegions,3);
    coneResponseDemosaic(isnan(coneResponseDemosaic))=0;
    
    x = (-floor(size(coneResponseDemosaic,1)/2):floor(size(coneResponseDemosaic,1)/2));
    distanceMatrix = sqrt(bsxfun(@plus,(x.^2)',(x.^2)));
    
    % Thickness of annular regions
    dl =  floor(size(coneResponseDemosaic,1)/2)/nAnnularRegions;
    
    
    tempResponse = [];
    for kk = 1 : nAnnularRegions
        [tempx, tempy] = find((distanceMatrix > (kk-1)*dl).*(distanceMatrix <= kk*dl));
        averageResponse(kk,:) = squeeze(mean(mean(coneResponseDemosaic(tempx,tempy,:),1),2))';
    end

end

