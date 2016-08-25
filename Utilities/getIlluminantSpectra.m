function [spectra, spdFiles] = getIlluminantSpectra(hints)
%% Get some illuminant spectra from VirtualWorldColorConstancy/Illuminants.
%
% [spectra, spdFiles] = getIlluminantSpectra(hints) reads various
% illuminant spectral power distributions from the accompanying folder
% VirtualWorldColorConstancy/Illuminants.
%
% Copies each spectrum file to the resources folder indicated by the given
% hints.workingFolder.
%
% Returns a cell array of spectrum descriptions suitable for use with
% ToyVirutalWorld scenes and the BuildToyRecipe() function.  Also returns a
% cell array of full paths to the spectrum files in the resources folder.

parser = inputParser();
parser.addRequired('hints', @isstruct);
parser.parse(hints);
hints = GetDefaultHints(parser.Results.hints);

resources = GetWorkingFolder('resources', false, hints);

%% Locate the original spectrum files.
parentPath = fileparts(fileparts(mfilename('fullpath')));
spectrumFolder = fullfile(parentPath, 'Illuminants');
folderContents = dir(spectrumFolder);
nContents = numel(folderContents);
isSpectrum = false(1, nContents);
for cc = 1:nContents
    [~, ~, spectrumExt] = fileparts(folderContents(cc).name);
    isSpectrum(cc) = ~folderContents(cc).isdir && strcmp(spectrumExt, '.spd');
end
spectrumNames = {folderContents(isSpectrum).name};


%% Copy files to the resources folder and build descriptions.
nSpectra = numel(spectrumNames);
spdFiles = cell(1, nSpectra);
spectra = cell(1, nSpectra);
for ss = 1:nSpectra
    % copy to resource folder
    originalFile = fullfile(spectrumFolder, spectrumNames{ss});
    resourceFile = fullfile(resources, spectrumNames{ss});
    copyfile(originalFile, resourceFile, 'f');
    spdFiles{ss} = resourceFile;
    
    % build illuminant description
    resourceRelativePath = fullfile('resources', spectrumNames{ss});
    spectra{ss} = BuildDesription('light', 'area', ...
        {'intensity'}, ...
        {resourceRelativePath}, ...
        {'spectrum'});
end
