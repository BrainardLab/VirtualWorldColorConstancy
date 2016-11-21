function [allInfo, allRaster] = SummarizeToyVirtualWorldRecipes(varargin)
% Plot a "raster" of recipes from AWS, organized by conditions.
%
% This is a utility to make sure we have full coverage of recipes over
% luminances and reflectances, as we expect.
%
% You'd need to mount our S3 bucket named "render-toolbox-vwcc2".  Here are
% some instructions for mounting on OS X:
%   https://github.com/RenderToolbox3/rtb-support/wiki/Mounting-S3-on-OS-X
%
% SummarizeToyVirtualWorldRecipes() makes a "raster" plot summarizing
% coverage of our virutal world recipes as run on AWS, across luminance and
% reflectances, and at each stage of processing.
%
% SummarizeToyVirtualWorldRecipes( ... 'luminanceLevels', luminanceLevels)
% specify the luminance conditions to look for.  The default is [0.2 0.6].
%
% SummarizeToyVirtualWorldRecipes( ... 'reflectanceNumbers', reflectanceNumbers)
% specify the reflectance conditions to look for.  The default is [1 2].
%
% SummarizeToyVirtualWorldRecipes( ... 'bucketFolder', bucketFolder)
% specify the folder where our S3 bucket was mounted.  The default is
% '~/Desktop/render-toolbox-vwccs'.
%
% Returns a struct array of info about the recipes that were found.  This
% includes the paths to the recipe Working folder, as well as Originals,
% Rendered, Analysed, ConeResponse, and AllRenderings files.
%

parser = inputParser();
parser.addParameter('luminanceLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', 1:2, @isnumeric);
parser.addParameter('bucketFolder', '~/Desktop/render-toolbox-vwcc2', @ischar);
parser.parse(varargin{:});
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;
bucketFolder = parser.Results.bucketFolder;


%% Gather file info for all conditions.
allInfo = [];
allRaster = [];
nLuminances = numel(luminanceLevels);
nReflectances = numel(reflectanceNumbers);
for rr = 1:nReflectances
    % do reflectances first, for yas3fs cache locality
    reflectance = reflectanceNumbers(rr);
    
    for ll = 1:nLuminances
        luminance = luminanceLevels(ll);
        
        info = AwsRecipeForCondition2(luminance, reflectance, 'bucketFolder', bucketFolder);
        infoFields = fieldnames(info);
        nFields = numel(infoFields);
        
        if isempty(allInfo)
            allInfo = repmat(info, nLuminances, nReflectances);
            allRaster = false(nLuminances, nReflectances, nFields);
            
            % set up to plot as we go, because slow
            figure();
            commonXLim = [min(reflectanceNumbers) - 1, max(reflectanceNumbers) + 1];
            for ff = 1:nFields
                subplot(nFields, 1, ff);
                fieldName = infoFields{ff};
                title(fieldName);
                xlim(commonXLim);
                drawnow();
            end
            
        else
            allInfo(ll,rr) = info; %#ok
        end
        
        for ff = 1:nFields
            fieldName = infoFields{ff};
            allRaster(ll,rr,ff) = ~isempty(info.(fieldName)); %#ok
        end
    end
    
    % plot as we go, because slow
    for ff = 1:nFields
        luminancesFound = luminanceLevels(allRaster(:,rr,ff));
        luminancesNotFound = luminanceLevels(~allRaster(:,rr,ff));
        
        subplot(nFields, 1, ff);
        line(reflectance * ones(size(luminancesFound)), luminancesFound, ...
            'Marker', '.', ...
            'MarkerSize', 10, ...
            'LineStyle', 'none', ...
            'Color', [0 0.8 0.4]);
        line(reflectance * ones(size(luminancesNotFound)), luminancesNotFound, ...
            'Marker', 'x', ...
            'MarkerSize', 11, ...
            'LineStyle', 'none', ...
            'Color', [1 0 0]);
    end
    drawnow();
end
