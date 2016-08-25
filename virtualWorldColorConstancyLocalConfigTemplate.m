% ToyVirtualWorldConfigurationTemplate
%
% Set up machine specific prefs for the ToyVirtualWorld
%
% The goal of this project is to create a simple "toy" virtual world, so
% that we can start playing with AMA analysis using it.  We will then later
% swap in a less toy virtual world to try to draw some real conclusions.
%
% 2/10/16  vs, dhb   Wrote it.

%% Set up some parameters for portability
projectName = 'ToyVirtualWorld';
dataDirRoot = fullfile(rtbGetUserFolder(), 'VirtualWorldColorConstancy');
dataDirName = 'ToyVirtualWorld';
dataDir = fullfile(dataDirRoot,projectName,'');
if (~exist(dataDir,'dir'))
    mkdir(dataDir);
end
setpref(projectName, 'recipesFolder',dataDir);
setpref(projectName, 'workingFolder',fullfile(dataDir,'Working',''));