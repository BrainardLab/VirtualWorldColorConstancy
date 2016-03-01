%% Construct and archive a set of many Ward Land recipes.
%
% The idea here is to specify up front values for several parameter sets.
% Each parameter set contains possibilities for things like "which object
% do we insert?", "which material do we use", or "where do we insert the
% object?".
%
% Then we can iterate all the parameter sets using lots of nested loops and
% construct all the unique sets of parameter values.  I'll call one such
% set of parameter a "leaf".
%
% We could build one scene for each leaf.  In this case each scene would
% have just one inserted object.  We could also build scenes that contain
% multiple inserted objects.  Then the question is how many and which
% leaves go into each scene? 
%
% I think what we discussed is for each scene to have one leaf from each
% object.  This would be a very large space to explore.  For example, say
% we obtained 8 leaves each for objects a, b, and c.  From that raw
% material we could create 16^3 = 4096 scenes!  And that is only for 3
% objects and a low estimate of the number of leaves per scene.
%
% I am wondering if this is really what we want.  Or, is there some other
% way to explore the scene space that would be more practival?
%
% BSH

%% Overall configuration.
clear;
clc;

% batch renderer options
hints.renderer = 'Mitsuba';
hints.workingFolder = getpref('VirtualScenes', 'workingFolder');
hints.isPlot = false;

defaultMappings = fullfile( ...
    VirtualScenesRoot(), 'MiscellaneousData', 'DefaultMappings.txt');

% virutal scenes options for inserted objects
scaleMin = 0.25;
scaleMax = 2.0;
rotMin = 0;
rotMax = 359;

% where to save new recipes
projectName = 'ToyVirtualWorld';
recipeFolder = fullfile(getpref(projectName, 'recipesFolder'),'Originals');
if (~exist(recipeFolder, 'dir'))
    mkdir(recipeFolder);
end

%% Choose how many recipes to make and from what components.
baseSceneSet = { ...
    'CheckerBoard', ...
    'IndoorPlant'};

objectSet = { ...
    'Barrel', ...
    'BigBall'};

lightSet = { ...
    'BigBall', ...
    'SmallBall'};

%% Build multiple recipes based on the sets above.
objectConditions = [0 5];
lightConditions = [0 3];

nSceneConditions = numel(baseSceneSet);
nObjectConditions = numel(objectConditions);
nLightConditions = numel(lightConditions);
nRecipes = nSceneConditions * nObjectConditions * nLightConditions;

for ss = 1:nSceneConditions
    baseScene = baseSceneSet{ss};
    
    for oo = 1:nObjectConditions
        nObjects = objectConditions(oo);
        
        for ll = 1:nLightConditions
            nLights = lightConditions(ll);
            
            recipeName = sprintf('%s-%02d-Obj-%02d-Illum', baseScene, nObjects, nLights);
            hints.recipeName = recipeName;
            ChangeToWorkingFolder(hints);
            
            % copy resources into this recipe working folder
            [textureIds, textures, matteTextured, wardTextured, filePaths] = ...
                GetWardLandTextureMaterials(3:6, hints);
            [matteMacbeth, wardMacbeth] = GetWardLandMaterials(hints);
            lightSpectra = GetWardLandIlluminantSpectra(6500, 3000, [4000 12000], 20, hints);
            
            % choose a 50/50 mix of textured and Macbeth materials
            nPick = 10;
            textureInds = randi(numel(matteTextured), [1 nPick]);
            macbethInds = randi(numel(matteMacbeth), [1 nPick]);
            matteMaterials = cat(2, matteTextured(textureInds), matteMacbeth(macbethInds));
            wardMaterials = cat(2, wardTextured(textureInds), wardMacbeth(macbethInds));
            
            % choose objects, materials, lights, and spectra
            choices = GetWardLandChoices(baseScene, ...
                objectSet, nObjects, ...
                lightSet, nLights, ...
                scaleMin, scaleMax, rotMin, rotMax, ...
                matteMaterials, wardMaterials, lightSpectra);
            
            % assemble the recipe
            recipe = BuildWardLandRecipe( ...
                defaultMappings, choices, textureIds, textures, hints);
            
            % archive it
            archiveFile = fullfile(recipeFolder, hints.recipeName);
            excludeFolders = {'scenes', 'renderings', 'images', 'temp'};
            PackUpRecipe(recipe, archiveFile, excludeFolders);
        end
    end
end
