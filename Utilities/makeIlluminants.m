function makeIlluminants(nIlluminances, folderToStore, minMeanIlluminantLevel, maxMeanIlluminantLevel)
% makeIlluminants(nIlluminances, folderToStore, minMeanIlluminantLevel, maxMeanIlluminantLevel)
%
% Usage: 
%     makeIlluminants(10,'Illuminants', 10, 100);
%
% Description:
%   This function generates the illuminants for the base scenes. The
%   illuminace spectra are generated using the granada daylight library. We
%   first rescale each spectrum by the mean value of the spectrum over its 
%   wavelenght. Then we find the principal components of the rescaled 
%   spectrum. We choose the directions corresponding to the six largest 
%   eigenvalues. We sample new spectra from a multivariate random gaussian 
%   whose mean and variance correspond to the projection of the rescaled
%   spectra along the first six PCA directions. Finally each spectrum is
%   rescaled by a random number.
%
% Input:
%   nIlluminances = how many illuminants to generate
%   folderToStore = fodler where the illuminants are stored
%   minMeanIlluminantLevel = min value with which the spectrum is rescaled
%   maxMeanIlluminantLevel = max value with which the spectrum is rescaled
%
% VS wrote this

% Desired wl sampling
rescaling = 1;  % O no rescaling
                % 1 rescaling

S = [400 5 61];
theWavelengths = SToWls(S);

%% Load Granada Illumimace data
pathToIlluminanceData = fullfile(fileparts(fileparts(mfilename('fullpath'))),'Data/IlluminantSpectra');
load(fullfile(pathToIlluminanceData,'daylightGranadaLong'));
daylightGranadaOriginal = SplineSrf(S_granada,daylightGranada,S);

% Rescale spectrum by its mean
meanDaylightGranada = mean(daylightGranadaOriginal);
daylightGranadaRescaled = bsxfun(@rdivide,daylightGranadaOriginal,meanDaylightGranada);

% Center the data for PCA
if ~ rescaling 
    daylightGranadaRescaled = daylightGranadaOriginal;
end
meandaylightGranadaRescaled = mean(daylightGranadaRescaled,2);
daylightGranadaRescaledMeanSubtracted = bsxfun(@minus,daylightGranadaRescaled,meandaylightGranadaRescaled);

%% Analyze with respect to a linear model
B = FindLinMod(daylightGranadaRescaledMeanSubtracted,6);
ill_granada_wgts = B\daylightGranadaRescaledMeanSubtracted;
mean_wgts = mean(ill_granada_wgts,2);
cov_wgts = cov(ill_granada_wgts');

%% Generate some new illuminants
nNewIlluminaces = nIlluminances;
newIlluminance = zeros(S(3),nNewIlluminaces);
newIndex = 1;

if ~exist(folderToStore)
    mkdir(folderToStore);
end


illuminanceValues = 10.^(log10(minMeanIlluminantLevel) + (log10(maxMeanIlluminantLevel)-log10(minMeanIlluminantLevel)) * rand(1,nIlluminances));

for i = 1:nNewIlluminaces
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        ran_ill = B*ran_wgts+meandaylightGranadaRescaled;
        if (all(ran_ill >= 0))
            newIlluminance(:,newIndex) = ran_ill;
            newIlluminance(:,newIndex) = newIlluminance(:,newIndex)*(rand*max(meanDaylightGranada));
            newIndex = newIndex+1;
            OK = true;
        end        
    end
    filename = sprintf('illuminance_%03d.spd',i);
    fid = fopen(fullfile(folderToStore,filename),'w');
    fprintf(fid,'%3d %3.6f\n',[theWavelengths,illuminanceValues(i)*newIlluminance(:,i)]');
    fclose(fid);
end

end