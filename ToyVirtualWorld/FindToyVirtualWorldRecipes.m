function archiveFiles = FindToyVirtualWorldRecipes(recipeFolder, luminanceLevels, reflectanceNumbers)
% Find recipes by parameter values, in the given recipeFolder.
%
% archiveFiles = FindToyVirtualWorldRecipes(recipeFolder, luminanceLevels, reflectanceNumbers)
% searches the given recipeFolder for Toy Virtual World recipes.  If
% luminanceLevels and reflectanceNumbers are provided, searches for recipes
% based on their names, using these parameter values.  Otherwise, looks for
% all recipe archives in the given recipeFolder.

parser = inputParser();
parser.addRequired('recipeFolder', @ischar);
parser.addRequired('luminanceLevels', @isnumeric);
parser.addRequired('reflectanceNumbers', @isnumeric);
parser.parse(recipeFolder, luminanceLevels, reflectanceNumbers);
recipeFolder = parser.Results.recipeFolder;
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;

%% Locate packed-up recipes.
if isempty(luminanceLevels) || isempty(reflectanceNumbers)
    % find all recipes available
    archiveFiles = rtbFindFiles('root', recipeFolder, 'filter', '\.zip$');
    
else
    % look for recipes by name
    nLuminanceLevels = numel(luminanceLevels);
    nReflectances = numel(reflectanceNumbers);
    nScenes = nLuminanceLevels * nReflectances;
    archiveFiles = cell(1, nScenes);
    isFound = false(1, nScenes);
    
    for ll = 1:nLuminanceLevels
        targetLuminanceLevel = luminanceLevels(ll);
        for rr = 1:nReflectances
            reflectanceNumber = reflectanceNumbers(rr);
            
            recipeName = FormatRecipeName(targetLuminanceLevel, reflectanceNumber, '\w+', '\w+');
            recipePattern = [recipeName '\.zip$'];
            archiveMatches = rtbFindFiles('root', recipeFolder, 'filter', recipePattern);
            
            if isempty(archiveMatches)
                continue;
            else
                sceneIndex = rr + (ll-1)*nReflectances;
                archiveFiles(sceneIndex) = archiveMatches(1);
                isFound(sceneIndex) = true;
            end
        end
    end
    archiveFiles = archiveFiles(isFound);
end
