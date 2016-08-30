function [wavelengths, magnitudes, fileName] = LoadReflectanceByName(whichOne,theLuminanceTarget)
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
% [wavelengths, magnitudes, fileName] = LoadReflectanceByName(whichOne)
%

%% Locate the Reflectances folder.
pathHere = fileparts(which('LoadReflectanceByName'));
parentPath = fileparts(pathHere);
if isempty(theLuminanceTarget)
    reflectancesPath = fullfile(parentPath, 'Reflectances/OtherObjects');
else
    reflectancesPath = fullfile(parentPath, 'Reflectances/TargetObjects');
end

%% Choose one spectru file.
fileName = fullfile(reflectancesPath, whichOne);
[wavelengths, magnitudes] = ReadSpectrum(fileName);
