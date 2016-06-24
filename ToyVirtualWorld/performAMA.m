% Stimulus transformation for AMA

%% load Stimulus
% loads the responses for the L, M and S cones for all stimuli at all
% luminance levels.
% allAverageResponses : 3*(No. of annular regions) x (No. of images at each
%                                               luminance)*(luminance levels)
% luminance levels   : Luminance levels at which images are generated
% ctgInd             : Category Index (required for AMA)
load(stimulusAMA);

%% Stimulus Normalization
% Each stimulus vector needs to have mean zero and vector length of <=1 for
% AMA

s = allAverageResponses - repmat(mean(allAverageResponses,1),[size(allAverageResponses,1),1]);
s = s*diag(1./sqrt(sum(s.*s)));


