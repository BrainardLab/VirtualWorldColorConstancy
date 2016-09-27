function summary = SummarizeToyVirtualWorldJobs(varargin)
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
parser.addParameter('jobFilter', '^job', @ischar);
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
    'timingInfo', []);
nJobFolders = numel(jobFolders);
hasTimingInfo = false(1, nJobFolders);
for jj = 1:nJobFolders
    timingInfo = fullfile(jobRoot, jobFolders{jj}, ...
        'VirtualWorldColorConstancy', 'ToyVirtualWorld', 'ToyVirtualWorldTiming.mat');
    hasTimingInfo(jj) = 2 == exist(timingInfo, 'file');
    
    if ~hasTimingInfo(jj)
        continue;
    end
    summary(jj).timingInfo = load(timingInfo);
end
summary = summary(hasTimingInfo);


%% Plot info about each job.
nSummary = numel(summary);
timing = zeros(nSummary, 4);
counts = zeros(nSummary, 4);
for ss = 1:nSummary
    info = summary(ss).timingInfo.folderInfo;
    jobCounts = [info(2:end).nFiles];
    jobTiming = 24 * 60 * diff([info.lastModified]);
    
    timing(ss, :) = jobTiming ./ jobCounts;
    counts(ss, :) = jobCounts;
    legendLabels = {info(2:end).subfolder};
end

figure();
xAxis = 1:nSummary;

subplot(3, 1, 1);
bar(timing, 'stacked');
legend(legendLabels);
set(gca(), ...
    'XTick', xAxis, ...
    'XTickLabels', [summary.jobNumber]);
ylabel('mean time per recipe (minutes)');
commonXLim = get(gca(), 'XLim');

subplot(3, 1, 2);
bar(counts, 'stacked');
legend(legendLabels);
set(gca(), ...
    'XTick', xAxis, ...
    'XTickLabels', [summary.jobNumber], ...
    'XLim', commonXLim);
ylabel('recipe counts');

subplot(3, 1, 3);
line(xAxis, cumsum(counts(:, end)), ...
    'Color', [.8 0 0], ...
    'LineStyle', 'none', ...
    'Marker', '*');
xlabel('job number');
set(gca(), ...
    'XTick', xAxis, ...
    'XTickLabels', [summary.jobNumber], ...
    'XLim', commonXLim, ...
    'XGrid', 'on', ...
    'YTick', [0 1000 2500 4000 5500 7000 8500 10000], ...
    'YGrid', 'on', ...
    'YLim', [0 10000]);
ylabel('cumulative recipes');
