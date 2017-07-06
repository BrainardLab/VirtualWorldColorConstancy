% Create a job and AWS run script to run MakeToyRecipeByCombinations.
%
% This script will produce a job struct suitable for running RenderToolbox4
% example recipes and validations.
%
% It will produce a shell script suitable for running the job on a
% short-lived AWS instance, via SSH, under control of the local
% workstation.
%
% 2016-2017 Brainard Lab, University of Pennsylvania

%% The job we want to run.
%
% Name is baked into mjs-vwcc docker container via
% the VirtualWorldColorConstancy local hook script
% container.
job = mjsJob( ...
    'name', 'VirtualWorldColorConstancy', ...
    'toolboxCommand', 'tbUseProject(''VirtualWorldColorConstancy'');', ...
    'jobCommand', 'RunToyVirtualWorldRecipes()');

%% Choose AWS credentials and config.
% "aws" profile holds many boring but necessary parameters.  Try:
%   params = mjsGetEnvironmentProfile('aws')

% use a biggish instance type
instanceType = 'm4.large';

% where to put the output on the AWS instance
% this is matched up to the prefs for VirtualWorldColorConstancy
% baked into the local hook in the docker containing mjs-vwcc.
outputDir = ['/home/ubuntu/' job.name];

% use the date as the name for this data set
jobDate = datestr(now(), 'yyyy-mm-dd-HH-MM-SS');

% copy all the output to S3
bucketPath = ['s3://render-toolbox-vwcc3/' jobDate];
hostCleanupCommand = sprintf('aws s3 cp "%s" "%s" --recursive --region us-west-2', ...
    outputDir, ...
    bucketPath);

% generate AWS script
[status, result, awsCliScriptFile] = mjsExecuteAwsCli(job, ...
    'profile', 'aws', ...
    'dockerImage', 'brainardlab/mjs-vwcc:latest', ...
    'mountDockerSocket', true, ...
    'instanceType', instanceType, ...
    'outputDir', outputDir, ...
    'hostCleanupCommand', hostCleanupCommand, ...
    'dryRun', true);
