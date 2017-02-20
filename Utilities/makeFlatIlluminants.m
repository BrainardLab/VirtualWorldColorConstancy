function makeFlatIlluminants(nIlluminances, folderToStore, minValue, maxValue)
% makeFlatIlluminants(nIlluminances, folderToStore)
%
% This script generates spectrally flat illuminants for the base scenes.
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