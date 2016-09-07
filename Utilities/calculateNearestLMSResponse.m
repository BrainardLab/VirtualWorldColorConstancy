function allNNLMS = calculateNearestLMSResponse(numLMSCones,allLMSPositions,allLMSResponses,howManyNN)

% This funciton calculates the LMS cone response for the cones that are
% closest to the center pixel. The cones are not guaranteed to be on the
% target object.

%Allocate space
allNNLMS = zeros(howManyNN*3,size(allLMSResponses,2));


coneDistance = sqrt(sum(allLMSPositions.*allLMSPositions,2));
[sortedL indexL]=sort(coneDistance(1:numLMSCones(1,1)));
[sortedM indexM]=sort(coneDistance(numLMSCones(1,1)+1:numLMSCones(1,1)+numLMSCones(1,2)));
[sortedS indexS]=sort(coneDistance(numLMSCones(1,1)+numLMSCones(1,2)+1:...
                                        numLMSCones(1,1)+numLMSCones(1,2)+numLMSCones(1,3)));

allNNLMS(1:3:(howManyNN-1)*3+1,:) = allLMSResponses(indexL(1:howManyNN),:);
allNNLMS(2:3:(howManyNN-1)*3+2,:) = allLMSResponses(indexM(1:howManyNN)+numLMSCones(1,1),:);
allNNLMS(3:3:(howManyNN)*3,:)     = allLMSResponses(indexS(1:howManyNN)+numLMSCones(1,1)+numLMSCones(1,2),:);

end

