function makeFlatIlluminants(nIlluminances, folderToStore, minValue, maxValue)

% makeFlatIlluminants(nIlluminances, folderToStore, minValue, maxValue)
%
% Usage: 
%     makeFlatIlluminants(100,pwd, 150, 150);
%
% Description:
%     This script generates spectrally flat illuminants for the base scenes
%
% Input:
%   nIlluminances = number of spectra to be generated
%   folderToStore = folder where the spectra should be stored
%   minValue = minimum value of the spectra
%   maxValue = maximum value of the spectra
%
% VS wrote this
%

if ~exist(folderToStore)
    mkdir(folderToStore);
end

S = [400 5 61];
theWavelengths = SToWls(S);

illuminanceValues = logspace(log10(minValue),log10(maxValue),nIlluminances);
for i=1:nIlluminances
    flatIlluminant = illuminanceValues(i)*ones(61,1);
    illuminanceName = sprintf('illuminance_%03d.spd', i);
    fid = fopen(fullfile(folderToStore,illuminanceName),'w');
    fprintf(fid,'%3d %3.6f\n',[theWavelengths,flatIlluminant]');
    fclose(fid);
end

end