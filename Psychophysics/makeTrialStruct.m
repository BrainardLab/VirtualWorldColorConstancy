function S = makeTrialStruct(S, varargin)
% Make the structure for doing color comparison experiment
%
% Usage: 
%   makeTrialStruct(S);
%
% Description:
%   Use the strucutre with fields multispectral image, lightness levels and
%   reflectance number, (and maybe additional fields), to create a
%   strucutre for running the experiment. This will return the same struct 
%   with additional fields, like the standard and comparison lightness 
%   levels. The images that would be used in each trail. The lightness 
%   levels of the standard and comparison images for each trail, etc.
%
% Input:
%    S : Struct with fields multispectralImage, lightnessLevels and
%           reflectanceNumbers
%  Optional:
%    nTrails : Number of trials
%    stdY : Standard lightness level
%    cmpY : Comparison lightness level
%
% Output:
%    S : Struct with additional fields nTrials, trailStdIndex,
%    trialCmpIndex, stdY, cmpY, stdYInTrial, cmpYInTrial.
%
% S.nTrials : Number of trials
% S.trialStdIndex : Index of standard image to be used in the trials
% S.trialCmpIndex : Index of comparison image to be used in the trial, 
%               should be the same as S.trailStdIndex 
% S.stdY : standard lightness level
% S.cmpY : comparison lightness levels
% S.stdYInTrial : std lightness for each trial
% S.cmpYInTrial : cmp lightness for each trial

% 10/16/2017 VS wrote this
%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('nTrials', 10, @isnumeric);
parser.addParameter('stdY', 0.3778, @isnumeric);
parser.addParameter('cmpY', linspace(0.2, 0.6, 10), @isnumeric);
parser.parse(varargin{:});

nTrials = parser.Results.nTrials;
stdY = parser.Results.stdY;
cmpY = parser.Results.cmpY;

smallNumber = 10^(-4);

S.stdY = stdY;
S.cmpY = cmpY;
S.nTrials = nTrials;

indexOfStandardImages = find(abs(S.luminanceLevels-stdY) < smallNumber);

for ii = 1 : nTrials
    % Pick a random index for the standard image
    tempStdIndex = randi(length(indexOfStandardImages));
    S.trialStdIndex(ii) = indexOfStandardImages(tempStdIndex);
    S.stdYInTrial(ii) = S.luminanceLevels(S.trialStdIndex(ii));
    
    % Pick a comparison level
    tempCmpLvl = cmpY(randi(length(cmpY)));
    indexOfCmpImages = find(abs(S.luminanceLevels-tempCmpLvl) < smallNumber);
    S.trialCmpIndex(ii) = indexOfCmpImages(tempStdIndex);
    S.cmpYInTrial(ii) = S.luminanceLevels(S.trialCmpIndex(ii));
end
    S.cmpInterval = zeros(1,nTrials);
    tempIndex = randperm(nTrials);
    S.cmpInterval(tempIndex(1:ceil(nTrials/2))) = 1;

