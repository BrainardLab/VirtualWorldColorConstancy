% Surface reflectance example

% Clear
clear; close all;

% Desired wl sampling
S = [400 5 61];
nSurfaces = 10000;

%% Munsell surfaces
load sur_nickerson
sur_nickerson = SplineSrf(S_nickerson,sur_nickerson,S);
figure; clf;
plot(SToWls(S),sur_nickerson);

%% Vhrel surfaces
load sur_vrhel 
sur_vrhel = SplineSrf(S_vrhel,sur_vrhel,S);
figure; clf;
plot(SToWls(S),sur_vrhel);

%% Put them together
sur_all = [sur_nickerson sur_vrhel];

%% Analyze with respect to a linear model
B = FindLinMod(sur_all,6);
sur_all_wgts = B\sur_all;
mean_wgts = mean(sur_all_wgts,2);
cov_wgts = cov(sur_all_wgts');

%% Generate some new surfaces
nNewSurfaces = nSurfaces;
newSurfaces = zeros(S(3),nNewSurfaces);
newIndex = 1;
for i = 1:nNewSurfaces
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        ran_sur = B*ran_wgts;
        if (all(ran_sur >= 0) & all(ran_sur <= 1))
            newSurfaces(:,newIndex) = ran_sur;
            newIndex = newIndex+1;
            OK = true;
        end
    end
end
figure; clf;
plot(SToWls(S),newSurfaces);
    

%% 
theWavelengths = SToWls(S);
for ii = 1 : nSurfaces
filename = ['reflectance_' num2str(ii)  '.spd'];
fid = fopen(filename,'w');
fprintf(fid,'%3d %3.6f\n',[theWavelengths,newSurfaces(:,ii)]');
fclose(fid);
end
