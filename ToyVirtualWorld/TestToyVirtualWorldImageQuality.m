% Repeat some renderings with different sizes and qualities.
%
% Hi Vijay--
%
% This script should take an existing recipe and re-render it a few times,
% with various pixel sizes and ray tracing sample depths.  I think you can
% just start Matlab and run this script, and it should produce a timing
% plot at the end.  If not, then there's probably a bug.
%
% The way it works is actually pretty clunky.  The ray traching sample
% depth is chosen early on in the VirtualWorldColorConstancy configuration,
% and then baked into the generated recipe mappings file.  So it's not easy
% to change it.  What this script does is re-write the mappings file and
% change the sample depth by pattern matching.  Yuck!
%
% When we move to RenderToolbox3, version 3, this kind of thing should be
% easier to manipulate, because we will be able to manipulate everything by
% matlab struct, instead of text file... :-)
%
%   --Ben
%
% 2016 benjamin.heasly@gmail.com

tbUse({'VirtualWorldColorConstancy', 'isetbio'});

%% Overall Setup.
clear;
clc;

projectName = 'ToyVirtualWorld';
originalsFolder = fullfile(getpref(projectName, 'recipesFolder'), 'Originals');
qualityFolder = fullfile(getpref(projectName, 'recipesFolder'), 'Quality');

hints.renderer = 'Mitsuba';
hints.workingFolder = getpref(projectName, 'workingFolder');

%% Choose image quality params.
%   what did originally was 320x240 pixels, and 512 ray samples per pixel
%   here we are trying some higher qualities like 640x480 and/or 1042 pixelSamples
conditions = struct( ...
    'imageWidth', {320, 320, 640, 640}, ...
    'imageHeight', {240, 240, 480, 480}, ...
    'pixelSamples', {512, 1024, 512, 1024});
nConditions = numel(conditions);
for cc = 1:nConditions
    condition = conditions(cc);
    conditions(cc).name = sprintf('%dx%d-%d', ...
        condition.imageWidth, ...
        condition.imageHeight, ...
        condition.pixelSamples);
end

pixelSampleFind = 'Camera-camera_sampler:sampleCount.integer = 512';
pixelSamplePattern = 'Camera-camera_sampler:sampleCount.integer = %d';

%% Locate and render packed-up recipes.
archiveFiles = FindToyVirtualWorldRecipes(originalsFolder, [], []);
nScenes = numel(archiveFiles);

executeTimes = zeros(nScenes, nConditions);

parfor ii = 1:nScenes
    loopTimes = zeros(1, nConditions);
    
    for cc = 1:numel(conditions)
        condition = conditions(cc);
        
        recipe = [];
        try
            % get the recipe
            recipe = rtbUnpackRecipe(archiveFiles{ii}, 'hints', hints);
            recipePath = GetWorkingFolder('', false, recipe.input.hints);
            
            % modify the mappings file for the new ray sample depth
            [~, mappingsBase, mappingsExt] = fileparts(recipe.input.mappingsFile);
            fid = fopen(fullfile(recipePath, recipe.input.mappingsFile));
            mappingsText = fread(fid, '*char')';
            fclose(fid);
            
            pixelSampleChange = sprintf(pixelSamplePattern, condition.pixelSamples);
            newMappingsText = regexprep(mappingsText, pixelSampleFind, pixelSampleChange, 'once');
            newMappingsFile = [mappingsBase '-' condition.name mappingsExt];
            fid = fopen(fullfile(recipePath, newMappingsFile), 'w');
            fwrite(fid, newMappingsText);
            fclose(fid);
            recipe.input.mappingsFile = newMappingsFile;
            
            % modify rendering options
            recipe.input.hints.renderer = hints.renderer;
            recipe.input.hints.workingFolder = hints.workingFolder;
            recipe.input.hints.imageWidth = condition.imageWidth;
            recipe.input.hints.imageHeight = condition.imageHeight;
            
            % render
            tic();
            recipe = rtbExecuteRecipe(recipe, 'throwException', true);
            loopTimes(cc) = toc();
            
            % save the results in a separate folder
            [archivePath, archiveBase, archiveExt] = fileparts(archiveFiles{ii});
            qualityArchiveFile = fullfile(qualityFolder, [archiveBase '-' condition.name archiveExt]);
            excludeFolders = {'temp', 'resources', 'scenes'};
            rtbPackUpRecipe(recipe, qualityArchiveFile, 'ignoreFolders', excludeFolders);
            
        catch err
            SaveToyVirutalWorldError(qualityFolder, err, recipe, []);
        end
    end
    
    executeTimes(ii,:) = loopTimes;
end

%% Plot the timing results.
% for each recipe, a cluster of bars -- one for each condition
bar(executeTimes / 60);
legend({conditions.name})
ylabel('execute time (minutes)')
xlabel('recipe number')
