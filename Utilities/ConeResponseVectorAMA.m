function [LMSResponseVector, LMSPositions] = ConeResponseVectorAMA(coneResponse);

%function [LMSResponseVector, LMSPositions] = ConeResponseVectorAMA(coneResponse);
%
% % Not used anymore %%
%
% This function converts the LMS cone responses into a single vector with 
% LMS cone response and returns the responses and the positions of the
% cones
%
%
    LMSResponseVector = []; 
    LMSPositions = []; 
        
    for ii = 1  : 3
        tempIndices = find(coneResponse.coneIndicator(:,ii)>0);
        LMSResponseVector = ...
            [LMSResponseVector;coneResponse.isomerizationsVector(tempIndices)];
        LMSPositions = ...
            [LMSPositions;coneResponse.conePositions(tempIndices,:)];
    end


end

