function scales = generateLogUniformScalesOfGranada(nScales)
% scales = generateLogUniformScalesOfGranada(nScales)
%
% Usage: 
%     scales = generateLogUniformScalesOfGranada(100)
%
% Description:
%   This function generates the scales with which the illuminant specrta in
%   the base scenes are scaled with. The scales are chosen randomly from
%   the Granada dataset. We first find the maximum and the minimum value of
%   the Granada mean value. Then we choose scales uniformaly on the 
%   log10(min) and log10(max) range.
%
%
% Input:
%   nScales = number of scale factors to generate, scalar 1 by 1
%
% Output:
%   scales = scale factors, scalar nScales by 1
%
% VS wrote this
% April 16, 2018

pathToIlluminanceData = fullfile(fileparts(fileparts(mfilename('fullpath'))),'Data/IlluminantSpectra');
load(fullfile(pathToIlluminanceData,'daylightGranadaLong'));
meanDaylightGranada = mean(daylightGranada);
mm = minmax(meanDaylightGranada);

scales = 10.^(log10(mm(1)) + (log10(mm(2))-log10(mm(1))) * rand(1,nScales));


