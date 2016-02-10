% CreateToyVirtualWorld
%
% The goal of this program is to create a simple "toy" virtual world, so
% that we can start playing with AMA analysis using it.  We will then later
% swap in a less toy virtual world to try to draw some real conclusions.
%
% 2/10/16  vs, dhb   Wrote it.

%% Clear
clear; close all;

%% Set up some parameters for portability
bigProjectName = 'VirtualWorldColorConstancy';
projectName = 'ToyVirtualWorld';
dataDirRoot = '/Users1/Shared/Matlab/Analysis/';
dataDir = fullfile(dataDirRoot,bigProjectName,projectName,'');
if (~exist(dataDir,'dir'))
    mkdir(dataDir);
end
setpref(projectName, 'recipesFolder',dataDir);