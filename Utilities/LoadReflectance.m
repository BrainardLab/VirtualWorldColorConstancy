function [wavelengths, magnitudes, fileName] = LoadReflectance(whichOne)
%% Load a standard reflectance from the Reflectances/ folder.
%
% [wavelengths, magnitudes, fileName] = LoadReflectance(whichOne) loads one
% of the reflectance files from the Reflectances/ folder which is part of
% this repository.
%
% whichOne must be an index used to select a file -- the files are sorted
% by name, and then whichOne is used as an index into the sorted array.
% So, whichOne must be in [1 n], if there are n reflectnace files.
%
% Returns :
%   an array of m wavelengths
%   an array of m reflectance magnitudes
%   the name of the file that contained this data
%
% [wavelengths, magnitudes, fileName] = LoadReflectance(whichOne)
%

%% Locate the Reflectances folder.
pathHere = fileparts(which('LoadReflectance'));
parentPath = fileparts(pathHere);
reflectancesPath = fullfile(parentPath, 'Reflectances');

%% Identify and sort all the spectrum files.
folderListing = dir(reflectancesPath);
fileListing = folderListing(~[folderListing.isdir]);
names = {fileListing.name};
sortedNames = sort(names);

%% Choose one spectru file.
fileName = fullfile(reflectancesPath, sortedNames{whichOne});
[wavelengths, magnitudes] = ReadSpectrum(fileName);
