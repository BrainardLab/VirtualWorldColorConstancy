function recipeName = FormatRecipeName(luminance, reflectance, targetShapeName, baseSceneName)
% Choose a formatted recipeName based on parameters used for the recipe.
%
% recipeName = FormatRecipeName(luminance, reflectance, targetShapeName, baseSceneName)
% returns a recipe name based on the given parameters, using a stadard
% format.
%
% This lets us generate the same recipe name from different functions.

% parameters in the right order and widths
recipeName = sprintf('luminance-%0.4f-reflectance-%03d-%s-%s', ...
    luminance, ...
    reflectance, ...
    targetShapeName, ...
    baseSceneName);

% substitute _ for . so we get a nice file name
recipeName('.' == recipeName) = '_';
