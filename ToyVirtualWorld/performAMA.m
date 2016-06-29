% Stimulus transformation for AMA

%% load Stimulus
% loads the responses for the L, M and S cones for all stimuli at all
% luminance levels.
% allAverageResponses : 3*(No. of annular regions) x (No. of images at each
%                                               luminance)*(luminance levels)
% luminance levels   : Luminance levels at which images are generated
% ctgInd             : Category Index (required for AMA)

load('stimulusAMA');

%% Choose Annular average or all cones
    % We renormalize the response of LMS by dividing the response of each
    % cone to the average reponse of that cone type over the whole data
    % set. This sets the LMS reponses to comparable values.

bAnnular = 1;       % 1 : The average LMS response in concentric annular regions
                    % 0 : All LMS response

if (bAnnular) 
    s = allAverageAnnularResponses;
    nAnnularRegions = size(s,1)/3;
    for ii = 1 : 3
        s((ii-1)*nAnnularRegions+1:ii*nAnnularRegions,:) = ...
            s((ii-1)*nAnnularRegions+1:ii*nAnnularRegions,:)/...
             mean(mean(s((ii-1)*nAnnularRegions+1:ii*nAnnularRegions,:)));
    end
else
    s = allLMSResponses;
    tempConeIndices = [0,cumsum(numLMSCones)];
    for ii = 1 : 3
       s(tempConeIndices(ii)+1:tempConeIndices(ii+1),:) = ...
           s(tempConeIndices(ii)+1:tempConeIndices(ii+1),:)/...
           mean(mean(s(tempConeIndices(ii)+1:tempConeIndices(ii+1),:))); 
    end
end

%% Stimulus Normalization
% Each stimulus vector needs to have mean zero and vector length of <=1 for
% We 

s = s - repmat(mean(s,1),[size(s,1),1]);
s = s*diag(1./sqrt(sum(s.*s)));

%%
[f E minTimeSec] = amaR01('FLL','MAP',2,0,2,[],s,ctgInd',luminanceLevel,5.7,1.36,0.23,1,570,15,.1,.001,.01);

% [f E minTimeSec] = amaR01('SGD','MAP',2,0,2,[],s,ctgInd',luminanceLevel,5.7,1.36,0.23,1,570,15,.1,.001,.01);
