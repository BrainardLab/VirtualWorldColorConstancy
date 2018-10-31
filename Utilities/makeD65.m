function makeD65(folderToStore)
% makeD65(folderToStore)
%
% Usage: 
%     makeD65(folderToStore)
%
% Description:
%   This function generates D65 scaled by its mean.
%
% VS wrote this
% Oct 31, 2018

% Desired wl sampling
S = [400 5 61];
theWavelengths = SToWls(S);

theIlluminantData = load('spd_D65');
theIlluminant = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
theIlluminant = theIlluminant/mean(theIlluminant);

if ~exist(folderToStore)
    mkdir(folderToStore);
end

filename = sprintf('illuminance_%03d.spd',1);
fid = fopen(fullfile(folderToStore,filename),'w');
fprintf(fid,'%3d %3.6f\n',[theWavelengths,theIlluminant]');
fclose(fid);

end