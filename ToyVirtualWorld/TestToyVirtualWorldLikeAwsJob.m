% Run the same compute job that we use on AWS, for local comparison.
%
% Hi Vijay--
%
% This script should do the same job and look for the same time info that I
% was doing recently on AWS.  I think you can just start Matlab and run
% this script, and it should produce a timing plot at the end.  If not,
% then there's probably a bug.
%
% Heads up!  This script will clear out the ToyVirtualWorld working
% folder, including Originals, Rendered, Analysed, etc.
%
%   --Ben
%
% 2016 benjamin.heasly@gmail.com

tbUse({'VirtualWorldColorConstancy', 'isetbio'});

%% Overall Setup.
clear;
clc;

% start with fresh recipes folder -- affects timing info below.
projectName = 'ToyVirtualWorld';
workingFolder = fullfile(getpref(projectName, 'recipesFolder'));

%% Heads up!
if exist(workingFolder, 'dir')
    rmdir(workingFolder, 's');
end

%% The command I used on AWS.
RunToyVirtualWorldRecipes( ...
    'luminanceLevels', [.2 .2119], ...
    'reflectanceNumbers', 1:5, ...
    'executeWidth', 640, ...
    'executeHeight', 480, ...
    'analyzeWidth', 640, ...
    'analyzeHeight', 480);


%% Gather timing info.
d = dir(fullfile(workingFolder, 'Working', 'resources'));
makeStart = datenum(d(1).date);

d = dir(fullfile(workingFolder, 'Originals'));
makeEnd = datenum(d(1).date);
nOriginals = numel(d) - 2;

d = dir(fullfile(workingFolder, 'Rendered'));
executeEnd = datenum(d(1).date);
nRendered = numel(d) - 2;

d = dir(fullfile(workingFolder, 'Analysed'));
analyseEnd = datenum(d(1).date);
nAnalysed = numel(d) - 2;

d = dir(fullfile(workingFolder, 'ConeResponse'));
coneResponseEnd = datenum(d(1).date);
nConeResponse = numel(d) - 2;


%% Plot timing info.
timing = 24 * diff([makeStart makeEnd executeEnd analyseEnd coneResponseEnd]);
bar([timing; zeros(size(timing))], 'stacked');
legend( ...
    sprintf('Make %d', nOriginals), ...
    sprintf('Execute %d', nRendered), ...
    sprintf('Analyse %d', nAnalysed), ...
    sprintf('ConeResponse %d', nConeResponse))
