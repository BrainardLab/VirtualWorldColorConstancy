function makeOtherObjectReflectance(nSurfaces, folderToStore)
% makeOtherObjectReflectance(nSurfaces, folderToStore)
%
% Usage: 
%     makeOtherObjectReflectance(999,'ExampleFolderName');
%
% Description:
%    This function generates reflectance spectrum for the background
%    objects in virtual world project. The spectrum are generated using the
%    nickerson and the vrhel libraries. These libraries should be a part of
%    RenderToolbox. To generate the spectra, we first find out the pricipal
%    components of the spectra in the library. Then we choose the
%    directions corresponding to the largest six eigenvalues. We project
%    the spectra along these six directions and find out the mean and the
%    variance of this distribution. These are then used along with a
%    multinormal random distribution to generate new random spectra. 
%    Finally, We make sure that the reflectance spectra values are between
%    0 and 1 at all frequencies.
%
% Input:
%   nSurfaces = number of random spectra to generate
%   folderToStore = folder where the spectra are stored
%
% 8/10/16  VS  Wrote it.

% Desired wl sampling
S = [400 5 61];
theWavelengths = SToWls(S);

%% Load surface reflectances.
%
% These data files are in the Psychtoolbox, which we depend on.

% Munsell surfaces
load sur_nickerson
sur_nickerson = SplineSrf(S_nickerson,sur_nickerson,S);

% Vhrel surfaces
load sur_vrhel 
sur_vrhel = SplineSrf(S_vrhel,sur_vrhel,S);

% Put them together
sur_all = [sur_nickerson sur_vrhel];
sur_mean=mean(sur_all,2);
sur_all_mean_centered = bsxfun(@minus,sur_all,sur_mean);

%% Analyze with respect to a linear model
B = FindLinMod(sur_all_mean_centered,6);
sur_all_wgts = B\sur_all_mean_centered;
mean_wgts = mean(sur_all_wgts,2);
cov_wgts = cov(sur_all_wgts');

%% Generate some new surfaces
newSurfaces = zeros(S(3),nSurfaces);
newIndex = 1;

if ~exist(folderToStore)
    mkdir(folderToStore);
end

for i = 1:nSurfaces
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        ran_sur = B*ran_wgts+sur_mean;
        if (all(ran_sur >= 0) & all(ran_sur <= 1))
            newSurfaces(:,newIndex) = ran_sur;
            newIndex = newIndex+1;
            OK = true;
        end
    end
    filename = sprintf('reflectance_%03d.spd',i);
    fid = fopen(fullfile(folderToStore,filename),'w');
    fprintf(fid,'%3d %3.6f\n',[theWavelengths,newSurfaces(:,i)]');
    fclose(fid);
end    

end
