function SaveToyVirutalWorldError(recipeFolder, error, recipe, extra)
% Save error and recipe info to a standard folder.
%
% SaveToyVirutalWorldError(error, recipe) will save the given error info
% recipe, and extra infor to disk, using a standard name and subfolder
% inside the recipeFolder.  This gives us a convention for where to look
% for errors. It also allows us to use the save() function during Toy
% Virutal World runs, since save() is not allowed from directly inside
% parfor loops.

if isstruct(recipe)
    recipeName = recipe.input.hints.recipeName;
elseif ischar(recipe)
    recipeName = recipe;
else
    recipeName = 'recipe';
end
fprintf('Error for recipe "%s":\n%s', ...
    recipeName, ...
    error.message);

errorFolder = fullfile(recipeFolder, 'Errors');
if 7 ~= exist(errorFolder, 'dir')
    mkdir(errorFolder);
end

errorFile = fullfile(errorFolder, [recipeName '.mat']);
fprintf('Saving error info to "%s":\n%s', errorFile);

save(errorFile);
