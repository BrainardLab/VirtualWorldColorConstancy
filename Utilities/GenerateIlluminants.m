%% Generate some illuminant spectra from the daylight database at granada
%   @param nSpectra number of spectra to generate
%   @param hints struct of RenderToolbox3 options, see GetDefaultHints()
%
% @details
% Generates spectra using a linear model from the daylight dataset of
% granada. The data is generated randomly fitting a gaussian model to the
% SVD components.
%
% @details
% Writes any necessary spectrum definition spm-files to the working
% "resources" folder as indicated by hints.workingFolder. See
% rtbGetWorkingFolder().
%
% @details
% Returns a cell array of area light descriptions, as from
% BuildDesription().  Also returns a corresponding cell array of spd-file
% names.
%
% @details
% Usage:
%   [spectra, spdFiles] = GetWardLandIlluminantSpectra(mean, std, range, nSpectra, hints)
%
% @ingroup WardLand
function [spectra, spdFiles] = GenerateIlluminants(nSpectra, hints)

if nargin < 1 || isempty(nSpectra)
    nSpectra = 10;
end

if nargin < 2 || isempty (hints)
    resources = '';
else
    resources = rtbWorkingFolder('folder','resources', 'hints', hints);
end

S = [400 5 61];
theWavelengths = SToWls(S);

%% Load Granada Illumimace data
load daylightGranadaLong
daylightGranadaOriginal = SplineSrf(S_granada,daylightGranada,S);
meanDaylightGranada = mean(daylightGranadaOriginal);
daylightGranadaRescaled = daylightGranadaOriginal./repmat(meanDaylightGranada,[size(daylightGranadaOriginal,1),1]);
meandaylightGranadaRescaled = mean(daylightGranadaRescaled,2);
daylightGranadaRescaled = bsxfun(@minus,daylightGranadaRescaled,meandaylightGranadaRescaled);
%% Analyze with respect to a linear model
B = FindLinMod(daylightGranadaRescaled,6);
ill_granada_wgts = B\daylightGranadaRescaled;
mean_wgts = mean(ill_granada_wgts,2);
cov_wgts = cov(ill_granada_wgts');

%% Generate some new surfaces
newIlluminance = zeros(S(3),nSpectra);
newIndex = 1;
for i = 1:nSpectra
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        ran_ill = B*ran_wgts+meandaylightGranadaRescaled;
        if (all(ran_ill >= 0))
            newIlluminance(:,newIndex) = ran_ill;
            newIndex = newIndex+1;
            OK = true;
        end
    end
end

spectra = cell(1, nSpectra);
spdFiles = cell(1, nSpectra);
for ii = 1:nSpectra
    
    spdName = sprintf('Illuminant-%d.spd', ii);
    spectra{ii} = BuildDesription('light', 'area', ...
        {'intensity'}, ...
        {spdName}, ...
        {'spectrum'});
    
    spdFiles{ii} = fullfile(resources, spdName);
    if ~isempty(resources)
        rtbWriteSpectrumFile(theWavelengths, newIlluminance(:,ii), spdFiles{ii});
    end
end

