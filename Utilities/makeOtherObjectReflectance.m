function makeOtherObjectReflectance(nSurfaces, folderToStore)
% makeOtherObjectReflectance(nSurfaces, folderToStore)
%
% Generate reflectances for other objects, making sure that the
% reflectance at every wavelength is lower than 1.
%
% 8/10/16  vs, vs  Wrote it.

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
