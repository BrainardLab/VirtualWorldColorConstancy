function makeFlatIlluminants(nIlluminances, folderToStore, minValue, maxValue)
% makeFlatIlluminants(nIlluminances, folderToStore)
%
% This script generates spectrally flat illuminants for the base scenes.
if ~exist(folderToStore)
    mkdir(folderToStore);
end

S = [400 5 61];
theWavelengths = SToWls(S);

for i=1:nIlluminances
    flatIlluminant = (minValue + (maxValue-minValue).*rand())*ones(61,1);
    illuminanceName = sprintf('illuminance_%03d.spd', i);
    fid = fopen(fullfile(folderToStore,illuminanceName),'w');
    fprintf(fid,'%3d %3.6f\n',[theWavelengths,flatIlluminant]');
    fclose(fid);
end

end