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

% where to save new recipes
projectName = 'ToyVirtualWorld';
recipeFolder = fullfile(getpref(projectName, 'recipesFolder'),'Originals');
if (~exist(recipeFolder, 'dir'))
    mkdir(recipeFolder);
end

%% Choose various "raw materials" we will use in creating scenes.

% textured materials in matte and ward flavors
[textureIds, textures, matteTextured, wardTextured, filePaths] = ...
    GetWardLandTextureMaterials([], hints);

% Macbeth color checker materials in matte and ward flavors
[matteMacbeth, wardMacbeth] = GetWardLandMaterials(hints);

% CIE-LAB tempterature correlated daylight spectra
lightSpectra = GetWardLandIlluminantSpectra(6500, 3000, [4000 12000], 20, hints);


%% Which base scenes do we want?
%   This parameter set chooses some scenes found in
%   VirtualScenes/ModelRepository/BaseScenes
baseSceneSet(1) = ReadMetadata('CheckerBoard');
baseSceneSet(2) = ReadMetadata('IndoorPlant');

%% Which reflective objects do we want to insert?
%   This parameter set chooses some objects found in
%   VirtualScenes/ModelRepository/Objects
%   And for each one, assigns:
%       position
%       rotation
%       scale
%       material

metaData = ReadMetadata('Barrel');
objectSet(1).metadata = metaData;
objectSet(1).position = GetDonutPosition([0 0; 0 0; 0 0;], metaData.objectBox, [.5 .5 .5]);
objectSet(1).rotation = [45 60 0];
objectSet(1).scale = 1.5;
objectSet(1).matteMaterial = matteMacbeth{1};
objectSet(1).wardMaterial = wardMacbeth{1};


%% Which reflective objects do we want to insert?
%   This parameter set chooses some objects found in
%   VirtualScenes/ModelRepository/Objects
%   And for each one, assigns:
%       position
%       rotation
%       scale
%       material
%       emitted spectrum

lightSet(1).metadata = ReadMetadata('BigBall');


