function RunToyVirtualWorldRecipesOneAtATime(varargin)
% Make, Execute, and Analyze Toy Virtual World Recipes, one at a time.
%
% The idea of this function is to take luminance levels and reflectance
% numbers in pairs, and run one through one recipe for each pair.  This is
% an alternative to RunToyVirtualWorldRecipes(), which runs blocks of
% recipes in parallel.
%

%% Get inputs and defaults.
parser = inputParser();
parser.KeepUnmatched = true;
parser.addParameter('luminanceList', [], @isnumeric);
parser.addParameter('reflectanceList', [], @isnumeric);
parser.parse(varargin{:});
luminanceList = parser.Results.luminanceList;
reflectanceList = parser.Results.reflectanceList;


%% Run a recipe for each luminance-reflectance pair.
try
    nLuminances = numel(luminanceList);
    nReflectances = numel(reflectanceList);
    for pp = 1:min([nLuminances nReflectances])
        runArgs = cat(2, varargin, { ...
            'luminanceLevels', luminanceList(pp), ...
            'reflectanceNumbers', reflectanceList(pp)});
        RunToyVirtualWorldRecipes(runArgs{:});
    end
    
catch err
    workingFolder = fullfile(getpref('VirtualWorldColorConstancy', 'recipesFolder'));
    SaveToyVirutalWorldError(workingFolder, err, 'RunToyVirtualWorldRecipesOneAtATime', varargin);
end


%% Save timing info.
PlotToyVirutalWorldTiming();
