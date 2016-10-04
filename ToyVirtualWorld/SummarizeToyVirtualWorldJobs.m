function [summary, allErrors] = SummarizeToyVirtualWorldJobs(varargin)
% Plot timing and file counts for jobs, like jobs from AWS.
%
% summary = SummarizeToyVirtualWorldJobs() looks in the jobRoot folder (see
% below) for subfolders that contain a file called
% ToyVirtualWorldTiming.mat.  Each such subfolder counts as a job.  For
% each job shows some file counts and timing info:
%   - Average time per recipe for Originals, Rendererd, Analysed, and
%   ConeResponse recipes.
%   - File counts for Originals, Rendererd, Analysed, and ConeResponse
%   recipes.
%
% Returns a struct array with the same kind of information for each job.
% Also returns a struct array that summarizes all detected errors.
%
% SummarizeToyVirtualWorldJobs( ... 'jobRoot', jobRoot) specifies the root
% folder where to look for job folders.  The default is
% '~/Desktop/render-toolbox-vwcc'.
%
% SummarizeToyVirtualWorldJobs( ... 'jobFilter', jobFilter) specifies a
% regular expression to use as filter when searching for job folders.  The
% default is '^job' -- the name of each job folder must start with the
% string "job".
%
% 2016 benjamin.heasly@gmail.com

parser = inputParser();
parser.addParameter('jobRoot', '~/Desktop/render-toolbox-vwcc', @ischar);
parser.addParameter('jobFilter', 'job-', @ischar);
parser.parse(varargin{:});
jobRoot = parser.Results.jobRoot;
jobFilter = parser.Results.jobFilter;

%% Collect job folders under the jobRoot.
jobRootDir = dir(jobRoot);
nJobRoot = numel(jobRootDir);
jobFolders = cell(1, nJobRoot);
jobNumbers = zeros(1, nJobRoot);
isKeeper = false(1, nJobRoot);
for jj = 1:nJobRoot
    jobFolders{jj} = jobRootDir(jj).name;
    isKeeper(jj) = jobRootDir(jj).isdir && ~isempty(regexp(jobFolders{jj}, jobFilter, 'once'));
    
    isDigits = jobFolders{jj} >= '0' & jobFolders{jj} <= '9';
    if any(isDigits)
        jobNumbers(jj) = sscanf(jobFolders{jj}(isDigits), '%d');
    end
end
jobFolders = jobFolders(isKeeper);
jobNumbers = jobNumbers(isKeeper);

[jobNumbers, jobOrder] = sort(jobNumbers);
jobFolders = jobFolders(jobOrder);


%% Collect info about each job.
summary = struct( ...
    'jobName', jobFolders, ...
    'jobNumber', num2cell(jobNumbers), ...
    'timingInfo', [], ...
    'errorInfo', []);
nJobFolders = numel(jobFolders);
for jj = 1:nJobFolders
    % timing info
    timingFile = fullfile(jobRoot, jobFolders{jj}, ...
        'VirtualWorldColorConstancy', 'ToyVirtualWorld', 'ToyVirtualWorldTiming.mat');
    if 2 == exist(timingFile, 'file')
        summary(jj).timingInfo = load(timingFile);
    end
    
    % error info
    subfolders = {'Originals', 'Rendered', 'Analysed', 'ConeResponse'};
    for ss = 1:numel(subfolders)
        errorFolder = fullfile(jobRoot, jobFolders{jj}, ...
            'VirtualWorldColorConstancy', 'ToyVirtualWorld', subfolders{ss}, 'Errors');
        if 7 ~= exist(errorFolder, 'dir')
            continue;
        end
        
        errorDir = dir(errorFolder);
        errorFiles = errorDir(~[errorDir.isdir]);
        nErrors = numel(errorFiles);
        errorInfo = struct( ...
            'jobName', summary(jj).jobName, ...
            'jobNumber', summary(jj).jobNumber, ...
            'subfolder', subfolders{ss}, ...
            'errorFile', {errorFiles.name}, ...
            'errorFullPath', [], ...
            'errorData', [], ...
            'luminance', '?', ...
            'reflectance', '?');
        for ee = 1:nErrors
            errorInfo(ee).errorFullPath = fullfile(errorFolder, errorFiles(ee).name);
            errorInfo(ee).errorData = load(errorInfo(ee).errorFullPath);
            nameNumbers = sscanf(errorFiles(ee).name, 'luminance-%d_%d-reflectance-%d');
            if 3 == numel(nameNumbers)
                errorInfo(ee).luminance = sprintf('%d.%d', nameNumbers(1), nameNumbers(2));
                errorInfo(ee).reflectance = sprintf('%d', nameNumbers(3));
            end
        end
        summary(jj).errorInfo = errorInfo;
    end
end


%% Plot info about each job.
nSummary = numel(summary);
timing = zeros(nSummary, 4);
counts = zeros(nSummary, 4);
errorCounts = zeros(nSummary, 1);
for ss = 1:nSummary
    if isempty(summary(ss).timingInfo)
        continue;
    end
    info = summary(ss).timingInfo.folderInfo;
    jobCounts = [info(2:end).nFiles];
    jobTiming = 24 * 60 * diff([info.lastModified]);
    
    timing(ss, :) = jobTiming ./ jobCounts;
    counts(ss, :) = jobCounts;
    errorCounts(ss) = numel(summary(ss).errorInfo);
    legendLabels = {info(2:end).subfolder};
end

figure();
commonXAxis = 0:max(jobNumbers);
commonXLim = [commonXAxis(1)-1, commonXAxis(end)+1];

subplot(4, 1, 1);
bar(commonXAxis, timing, 'stacked');
legend(legendLabels, 'Location', 'southeast');
set(gca(), ...
    'XTick', commonXAxis, ...
    'XTickLabels', [summary.jobNumber], ...
    'XLim', commonXLim);
ylabel('mean time per recipe (minutes)');

subplot(4, 1, 2);
bar(commonXAxis, counts, 'stacked');
legend(legendLabels, 'Location', 'southeast');
set(gca(), ...
    'XTick', commonXAxis, ...
    'XTickLabels', [summary.jobNumber], ...
    'XLim', commonXLim);
ylabel('recipe counts');

subplot(4, 1, 3);
bar(commonXAxis, errorCounts, 'stacked');
set(gca(), ...
    'XTick', commonXAxis, ...
    'XTickLabels', [summary.jobNumber], ...
    'XLim', commonXLim);
ylabel('error counts');

subplot(4, 1, 4);
line(commonXAxis, cumsum(counts(:, end)), ...
    'Color', [.8 0 0], ...
    'LineStyle', 'none', ...
    'Marker', '*');
xlabel('job number');
set(gca(), ...
    'XTick', commonXAxis, ...
    'XTickLabels', [summary.jobNumber], ...
    'XLim', commonXLim, ...
    'XGrid', 'on', ...
    'YTick', [0 1000 2500 4000 5500 7000 8500 10000], ...
    'YGrid', 'on', ...
    'YLim', [0 10000]);
ylabel('cumulative recipes');


%% Print information about errors.
allErrors = [summary.errorInfo];
nErrors = numel(allErrors);
fprintf('Found %d errors:\n', nErrors);
for ee = 1:nErrors
    info = allErrors(ee);
    fprintf('  %15s\t%s\t%s\t%s\t%s\n', ...
        info.jobName, ...
        info.subfolder, ...
        info.luminance, ...
        info.reflectance, ...
        regexprep(info.errorData.error.message, '[\r\n]+', ' '));
end
