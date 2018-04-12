function scales = generateIlluminantsScalesForScene(nScales)
% scales = generateIlluminantsScalesForScene(nScales)
%
% Usage: 
%     scales = generateIlluminantsScalesForScene(100)
%
% Description:
%   This function generates the scales with which the illuminant specrta in
%   the base scenes are scaled with. The scales are chosen randomly from
%   the Granada dataset. We first select a spectrum uniformly at random
%   from the dataset. The scale factor is the mean value of the spectrum
%   over the wavelengths.
%
% Input:
%   nScales = number of scale factors to generate, scalar 1 by 1
%
% Output:
%   scales = scale factors, scalar nScales by 1
%
% VS wrote this
% April 12, 2018

pathToIlluminanceData = fullfile(fileparts(fileparts(mfilename('fullpath'))),'Data/IlluminantSpectra');
load(fullfile(pathToIlluminanceData,'daylightGranadaLong'));
meanDaylightGranada = mean(daylightGranada);

scales = randi(length(meanDaylightGranada), nScales,1);
scales = meanDaylightGranada(scales);


