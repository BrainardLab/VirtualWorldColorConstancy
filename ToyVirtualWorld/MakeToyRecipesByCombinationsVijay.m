%% Construct and archive a set of many Ward Land recipes.
%
% The idea here is to generate many WardLand scenes.  We choose values for
% several parameter sets and build a scene for several combinations of
% values, taken from each set.
%
% Here are the parameter set's we're working with:
%
% reflectanceSet -- select several reflectances.  For each of these,
% we want to generate on the order of 100 scenes.  The generated scenes
% will be named after this reflectance.  The "center" object of the scene
% will use this reflectance.
%
% shapeSet -- select several 3D models which can be inserted into slots.
% The models are identified by name and correspond to files located in
%   VirtualScenes/ModelRepository/Objects
%
% objectSlotSet -- chooses some "slots" where we can insert objects into
% the scene.  The first slot is for the "center" object which gets the
% fixedReflectance.  The remaining slots are for other objects.  Here are
% the parameters that make up a slot:
%	position, relative to scene bounding boxes
%	rotation
%	scale
%
% baseSceneSet -- select several 3D models which make up most of the scene
% geometry and camera.  The models are identified by name and correspond to
% files located in
%   VirtualScenes/ModelRepository/BaseScenes
%
% lightSet -- choose some light sources to insert into the scene.  Here are
% the parameters tha make up a light:
%   one of the 3D models in VirtualScenes/ModelRepository/Objects
%	position, relative to scene bounding boxes
%	rotation
%	scale
%	material
%	emitted spectrum
%
% Here's how we combine all these sets to make each scene:
%   - iterate the baseSceneSet, one at a time
%   - iterate the lightSet, one at a time
%   - iterate the reflectanceSet, one at a time
%   - iterate the shapeSet, one at a time
%   - apply the chosen reflectance and shape to the "center" object in the
%   first object slot
%   - fill the remaining object slots by shuffling the remaining
%   reflectances and shapes.  Do this a small, fixed number of times (don't
%   be exhaustive with the shuffling permutations).  Call this nShuffles.
%   - pack all this up as a scene
%
% From this outline, we can figure out how many scenes we'll get:
%   nScenes = ...
%       nFixedReflectances * nShapes * nShuffles * nBaseScenes * nLights;
%
% The number of object slots doesn't affect the number of total scenes
% because we use all of the object slots every time.
%
% The number of reflectances and shapes must be at least as great as the
% number of object slots.
%
% BSH

%% Overall configuration.
clear;
clc;

% batch renderer options
projectName = 'ToyVirtualWorld';
hints.renderer = 'Mitsuba';
hints.workingFolder = getpref(projectName, 'workingFolder');
hints.isPlot = false;

defaultMappings = fullfile( ...
    VirtualScenesRoot(), 'MiscellaneousData', 'DefaultMappings.txt');

% where to save new recipes
recipeFolder = fullfile(getpref(projectName, 'recipesFolder'),'Originals');
if (~exist(recipeFolder, 'dir'))
    mkdir(recipeFolder);
end

%% Choose various "raw materials" we will use in creating scenes.

% textured materials in matte and ward flavors
[textureIds, textures, matteTextured, wardTextured, textureFiles] = ...
    GetWardLandTextureMaterials([], hints);

% Macbeth color checker materials in matte and ward flavors
[matteMacbeth, wardMacbeth] = GetWardLandMaterials(hints);

% CIE-LAB tempterature-correlated daylight spectra
lowTemp = 4000;
highTemp = 12000;
nSpectra = 20;
temps = round(linspace(lowTemp, highTemp, nSpectra));
lightSpectra = cell(1, nSpectra);
for bb = 1:nSpectra
    lightSpectra(bb) = GetWardLandIlluminantSpectra( ...
        temps(bb), ...
        0, ...
        [lowTemp highTemp], ...
        1, ...
        hints);
end

% remember where these raw materials are so we can copy them, below
commonResourceFolder = GetWorkingFolder('resources', false, hints);

%% Choose our reflectances.

% WardLand expects reflectances in matt-ward pairs.
matteReflectanceSet = cat(2, matteTextured(1:2), matteMacbeth(1:2));
wardReflectanceSet = cat(2, wardTextured(1:2), wardMacbeth(1:2));

%% Which shapes do we want to insert into slots?
shapeSet = { ...
    'BigBall', ...
    'SmallBall', ...
    'RingToy', ...
    'Barrel'};

%% Which base scenes do we want?
baseSceneSet = { ...
    'CheckerBoard', ...
    'IndoorPlant', ...
    'Library', ...
    'TableChairs'};

%% How many scenes are we making?
nReflectance = 5;
% nReflectances = numel(reflectanceNameSet);
nShapes = numel(shapeSet);
nBaseScenes = numel(baseSceneSet);


%% 
% The first loop runs through the target luminance levels for the standard day-light oberserver
% The second loop runs through the reflectance levels we want to use in
% rendering
    
for targetLuminanceLevel = 0.1 : 0.1 :1
    for rr = 1 : 1 : nReflectance
        [theWavelengths, theReflectance, theReflectanceScaled, theLuminance] = ...
            computeLuminance(rr, targetLuminanceLevel);
        targetMaterialRefelectance = theReflectanceScaled;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Pick the base scene
        bIndex = randi(size(baseSceneSet,2),1); % index for the base scene chosen randomly
        choices.baseSceneName = baseSceneSet{bIndex};
        sceneData = ReadMetadata(choices.baseSceneName);
        nBaseMaterials = numel(sceneData.materialIds);
        whichMaterials = 1 + mod((1:nBaseMaterials)-1, numel(matteMacbeth));
        choices.baseSceneMatteMaterials = matteMacbeth(whichMaterials);
        choices.baseSceneWardMaterials = wardMacbeth(whichMaterials);
    
        % assign arbitrary but constant light spectra for the base scene itself
        nBaseLights = numel(sceneData.lightIds);
        whichLights = 1 + mod((1:nBaseLights)-1, numel(lightSpectra));
        choices.baseSceneLights = lightSpectra(whichLights);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Pick the light Source
        light.name = shapeSet{randi(nShapes,1)};
        light.boxPosition = rand(1,3);
        light.rotation = randi(180, 1, 3);
        light.scale = 1 + rand();
        ll = randi(size(matteMacbeth,2),1);
        light.matteMaterial = matteMacbeth{ll};
        light.wardMaterial = wardMacbeth{ll};
        light.lightSpectrum = lightSpectra{randi(nSpectra)};
        
        % convert the abstract "box positoin" into a concrete xyz
        % within the chosen base scene
        lightPosition = GetDonutPosition( ...
            sceneData.lightExcludeBox, sceneData.lightBox, light.boxPosition);
        
        % pack up the light in the format expected for Ward Land
        choices.insertedLights.names = {light.name};
        choices.insertedLights.positions = {lightPosition};
        choices.insertedLights.rotations = {light.rotation};
        choices.insertedLights.scales = {light.scale};
        choices.insertedLights.matteMaterialSets = {light.matteMaterial};
        choices.insertedLights.wardMaterialSets = {light.wardMaterial};
        choices.insertedLights.lightSpectra = {light.lightSpectrum};
       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Pick the target object
        targetShapeIndex = randi(nShapes,1);
        targetShapeName = shapeSet{targetShapeIndex};
        
        nOtherShapes = 1+randi(5); % number of other shapes inserted apart from target shape
        otherShapeIndex = randi(nShapes,1,nOtherShapes);
        
        shapeInds = [targetShapeIndex otherShapeIndex];
 
        for oo = 1: (1+nOtherShapes)
            objectSlotSet(oo).boxPosition = rand(3,1);
            objectSlotSet(oo).rotation = randi(180,3,1);
            objectSlotSet(oo).scale = 0.5 + rand();
        end
        
        nSlots = numel(objectSlotSet);
        reflectanceInds = randi(nReflectance,1,nOtherShapes);
        
        % format our selections as a WardLand "choices" struct
        
        choices.insertedObjects.names = shapeSet(shapeInds);
        choices.insertedObjects.rotations = {objectSlotSet.rotation};
        choices.insertedObjects.scales =  {objectSlotSet.scale};
%         choices.insertedObjects.matteMaterialSets = matteReflectanceSet(reflectanceInds);
%         choices.insertedObjects.wardMaterialSets = wardReflectanceSet(reflectanceInds);
        choices.insertedObjects.positions = cell(1, nSlots);
        for oo = 1:nSlots
            % "box position" -> xyz in chosen base scene
            slot = objectSlotSet(oo);
            choices.insertedObjects.positions{oo} = ...
            GetDonutPosition([0 0; 0 0; 0 0], sceneData.objectBox, slot.boxPosition);
        end
                    
        
        
    end
end
