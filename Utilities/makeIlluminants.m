function makeIlluminants(nIlluminances, folderToStore, minMeanIlluminantLevel, maxMeanIlluminantLevel)
% makeIlluminants(nIlluminances, folderToStore)
%
% This script generates the illuminants for the base scenes. The
% illuminace spectra are generated using the library obtained from the
% granada daylight spectra.

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