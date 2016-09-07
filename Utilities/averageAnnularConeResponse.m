function [ averageResponse ] = averageAnnularConeResponse(nAnnularRegions, coneResponse)
% This function calcuates the LMS cone responses in concentric annular
% regions wiht the center at the center pixel of the cone mosaic.

    averageResponse=zeros(nAnnularRegions,3);
    
    % Distance from center pixel
    coneDistance = sqrt(sum(coneResponse.conePositions.*coneResponse.conePositions,2));
    
    % Thickness of annular regions
    dl =  max(max(abs(coneResponse.conePositions)))/nAnnularRegions;
    
    
    tempResponse = [];
    for kk = 1 : nAnnularRegions
        tempIndices = find(coneDistance >= (kk-1)*dl & coneDistance < kk*dl);
        tempResponse= (coneResponse.isomerizationsVector(tempIndices)*[1,1,1]).*coneResponse.coneIndicator(tempIndices,:);
        for jj = 1 : 3
        averageResponse(kk,jj)= mean(tempResponse(tempResponse(:,jj)>0,jj));
        end
    end
     averageResponse(isnan(averageResponse))=0;

end

