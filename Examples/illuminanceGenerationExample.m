% Illuminance Generation example

% Clear
clear; close all;

% Desired wl sampling
S = [400 5 61];
nIlluminances = 100;

theWavelengths = SToWls(S);
%% Load Granada Illumimace data
load ill_granada
ill_granada = SplineSrf(S_granada,ill_granada,S);
figure; clf;
plot(SToWls(S),ill_granada);

%% Analyze with respect to a linear model
B = FindLinMod(ill_granada,10);
ill_granada_wgts = B\ill_granada;
mean_wgts = mean(ill_granada_wgts,2);
cov_wgts = cov(ill_granada_wgts');

%% Generate some new surfaces
nNewIlluminaces = nIlluminances;
newIlluminance = zeros(S(3),nNewIlluminaces);
newIndex = 1;
for i = 1:nNewIlluminaces
    OK = false;
    while (~OK)
        ran_wgts = mvnrnd(mean_wgts',cov_wgts)';
        ran_ill = B*ran_wgts;
        if (all(ran_ill >= 0))
            newIlluminance(:,newIndex) = ran_ill;
            newIndex = newIndex+1;
            OK = true;
        end
    end
end
figure; clf;
plot(SToWls(S),newIlluminance);

%% Load in the T_xyz1931 data for luminance sensitivity
theXYZData = load('T_xyz1931');
theLuminanceSensitivity = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);

%% Compute XYZ
XYZordinates = theLuminanceSensitivity*newIlluminance;
xyYordiantes = XYZToxyY(XYZordinates);
%%
figure; clf;
plot(xyYordiantes(1,:),xyYordiantes(2,:),'.');
%% 
theWavelengths = SToWls(S);
for ii = 1 : nIlluminances
filename = ['illuminance_' num2str(ii)  '.spd'];
fid = fopen(filename,'w');
fprintf(fid,'%3d %3.6f\n',[theWavelengths,newIlluminance(:,ii)]');
fclose(fid);
end
