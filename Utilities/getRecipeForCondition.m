function info = getRecipeForCondition(luminanceLevel, reflectanceNumber, varargin)
% Get paths to a Toy Virutal World Recipe that we rendered on AWS.
%
% This is a utility to make it easier to find recipes, without worrying
% about how we organized our AWS jobs.
%
% This specific script, AwsRecipeForCondition2, is intended to work with
% our second production run on AWS, which I call "vwcc2".
%
% You'd need to mount our S3 bucket named "render-toolbox-vwcc2".  Here are
% some instructions for mounting on OS X:
%   https://github.com/RenderToolbox3/rtb-support/wiki/Mounting-S3-on-OS-X
%
% This function is a hack!  It contains several hard-coded values that are
% specific to our AWS jobs.  This is necessary because the file mount
% is a slow interface to S3, and we have some 10 million of files to search
% through, so regular file searching would be really slow.
%
% recipePath = AwsRecipeForCondition2(luminanceLevel, reflectanceNumber)
% searches our S3 bucket mount for the recipe that was run with the given
% luminance level and reflectance number.
%
% AwsRecipeForCondition2( ... 'bucketFolder', bucketFolder) specify the
% folder where our S3 bucket was mounted.  The default is
% '~/Desktop/render-toolbox-vwcc2'.
%
% Returns a struct of info about the recipe, if found.  This includes the
% paths to the recipe Working folder, as well as Originals, Rendered,
% Analysed, ConeResponse, and AllRenderings files.
%

parser = inputParser();
parser.addRequired('luminanceLevel', @isnumeric);
parser.addRequired('reflectanceNumber', @isnumeric);
parser.addParameter('bucketFolder', '~/Desktop/render-toolbox-vwcc2', @ischar);
parser.addParameter('jobFolder', 'none', @ischar);
parser.parse(luminanceLevel, reflectanceNumber, varargin{:});
luminanceLevel = parser.Results.luminanceLevel;
reflectanceNumber = parser.Results.reflectanceNumber;
bucketFolder = parser.Results.bucketFolder;
jobFolder = parser.Results.jobFolder;

%% Prefer recipe in the re-do folder aka "job-omega".
if strcmp(jobFolder,'')
    omegaFolder =  'job-omega';
    namePattern = FormatRecipeName(luminanceLevel, reflectanceNumber, '*', '*');
    workingOmega = recipeInfoForPattern(bucketFolder, omegaFolder, 'Working', namePattern);
    if isempty(workingOmega)
        % this was not a re-do, use a regular, numbered job folder
        [jobFolder, jobNumber] = jobFolderForCondition(luminanceLevel, reflectanceNumber);
    else
        % this was a re-do, use the distinguished "omega" job folder
        jobFolder = omegaFolder;
        jobNumber = 0;
    end
end

%% Dig out files from each stage of recipe processing.
namePattern = FormatRecipeName(luminanceLevel, reflectanceNumber, '*', '*');
subfolders = {'Working', 'Originals', 'Rendered', 'Analysed', 'ConeResponse', 'AllRenderings'};
for ss = 1:numel(subfolders)
    subfolder = subfolders{ss};
    info.(subfolder) = recipeInfoForPattern(bucketFolder, jobFolder, subfolder, namePattern);
    if ~isempty(info.(subfolder))
%         info.(subfolder).jobNumber = jobNumber;
    end
end


%% Check for a recipe file or folder in the given job folder and subfolder.
function info = recipeInfoForPattern(bucketFolder, jobFolder, subfolder, namePattern)
subFolderPath = fullfile(bucketFolder, jobFolder, 'VirtualWorldColorConstancy', subfolder);
recipePattern = fullfile(subFolderPath, namePattern);
info = dir(recipePattern);

if ~isempty(info)
    info.bucketFolder = bucketFolder;
    info.jobFolder = jobFolder;
    info.subfolder = subfolder;
    info.namePattern = namePattern;
    info.fullPath = fullfile(subFolderPath, info.name);
end


%% Hard-coded map for looking up job fodlers based on parameters.
function [jobFolder, jobNumber] = jobFolderForCondition(luminanceLevel, reflectanceNumber)

% don't actually need luminanceLevel

% we divided up jobs 10 reflectances at a time
reflectancesPerJob = 10;
jobNumber = ceil(reflectanceNumber / reflectancesPerJob);

% we had a consistent naming convention for jobs
jobFolder = sprintf('job-%d', jobNumber);
