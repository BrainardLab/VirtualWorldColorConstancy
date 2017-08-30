function allNNLMS = calculateNearestLMSResponse(numLMSCones,allLMSPositions,allLMSResponses,howManyNN)
%
% CAUTION :: This function probably does not work now. This is because the
% convention of the LMS positions was changed in the main file. Check
% before using.
%
% allNNLMS = calculateNearestLMSResponse(numLMSCones,allLMSPositions,allLMSResponses,howManyNN)
%
% Usage: 
%     allNNLMS = calculateNearestLMSResponse(numLMSCones,allLMSPositions,allLMSResponses,9)
%
% Description:
%   This funciton calculates the LMS cone response for the cones that are
%   closest to the center pixel. The cones are not guaranteed to be on the
%   target object.
%
% Input:
%   numLMSCones = 1 x 3 vector having the number of LMS cones
%   allLMSPositions = positions of the cones
%   allLMSResponses = LMS cone responses
%   howManyNN = scalar number of nearest neighbors to get the cone responses from
%
% Output:
%   allNNLMS = matrix with NN cone responses
%
%Allocate space
allNNLMS = zeros(howManyNN*3,size(allLMSResponses,2));


coneDistance = sqrt(sum(allLMSPositions.*allLMSPositions,2));
[~, indexL]=sort(coneDistance(1:numLMSCones(1,1)));
[~, indexM]=sort(coneDistance(numLMSCones(1,1)+1:numLMSCones(1,1)+numLMSCones(1,2)));
[~, indexS]=sort(coneDistance(numLMSCones(1,1)+numLMSCones(1,2)+1:...
                                        numLMSCones(1,1)+numLMSCones(1,2)+numLMSCones(1,3)));

allNNLMS(1:3:(howManyNN-1)*3+1,:) = allLMSResponses(indexL(1:howManyNN),:);
allNNLMS(2:3:(howManyNN-1)*3+2,:) = allLMSResponses(indexM(1:howManyNN)+numLMSCones(1,1),:);
allNNLMS(3:3:(howManyNN)*3,:)     = allLMSResponses(indexS(1:howManyNN)+numLMSCones(1,1)+numLMSCones(1,2),:);

end

