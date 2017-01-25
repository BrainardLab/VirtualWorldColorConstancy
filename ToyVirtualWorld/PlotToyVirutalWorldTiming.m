function folderInfo = PlotToyVirutalWorldTiming(varargin)
%% Plot ToyVirtualWorld execution times based on folder timestamps.
%
% folderInfo = PlotToyVirutalWorldTiming() examines several subfolders of
% the ToyVirtualWorld project folder for modification timestamps and file
% counts, and plots a bar chart with the results of each phase of
% execution, like recipe generation, rendering, analysis, etc.
%
% Saves the plot figure in the same project folder, which is important for
% remote execution.
%
% Also returns a struct of folder information.  Also saves a mat-file with
% the same folder information in the project folder.

parser = inputParser();
parser.addParameter('outputName','ExampleOutput',@ischar);
% parser.addParameter('workingFolder', fullfile(getpref('VirtualWorldColorConstancy', 'baseFolder'),parser.Results.outputName), @ischar);
parser.parse(varargin{:});
workingFolder = fullfile(getpref('VirtualWorldColorConstancy', 'baseFolder'),parser.Results.outputName);

%% Collect and save some file and timing info.
subfolderNames = { ...
    fullfile('Working', 'resources'), ...
    'Originals', ...
    'Rendered', ...
    'Analysed', ...
    'ConeResponse', ...
    };

folderInfo = struct( ...
    'subfolder', subfolderNames, ...
    'fullPath', [], ...
    'dir', [], ...
    'lastModified', [], ...
    'nFiles', [], ...
    'label', []);
nFolders = numel(folderInfo);
for ff = 1:nFolders
    folderInfo(ff).fullPath = fullfile(workingFolder, folderInfo(ff).subfolder);
    d = dir(folderInfo(ff).fullPath);
    folderInfo(ff).dir = d;
    if isempty(d)
        folderInfo(ff).lastModified = nan;
        folderInfo(ff).nFiles = 0;
    else
        folderInfo(ff).lastModified = datenum(d(1).date);
        folderInfo(ff).nFiles = numel(d) - 2;
    end
    folderInfo(ff).label = sprintf('%s %d', folderInfo(ff).subfolder, folderInfo(ff).nFiles);
end

folderInfoFile = fullfile(workingFolder, 'VirtualWorldColorConstancyTiming');
save(folderInfoFile);


%% Plot timing info.
timing = 60 * 24 * diff([folderInfo.lastModified]);
bar([timing; zeros(size(timing))], 'stacked');
legend({folderInfo(2:end).label});
set(gca(), 'XTick', 1, 'XTickLabel', {});
ylabel('processing time (minutes)');
title('VirtualWorldColorConstancy Timing');

figureFile = fullfile(workingFolder, 'VirtualWorldColorConstancyTiming');
savefig(figureFile);

