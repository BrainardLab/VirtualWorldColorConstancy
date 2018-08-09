% Condition3.m
% This script renders 3000 images for condition 3. 
% This number rendered can be changed by setting
% option reflectanceNumbers. For example, setting it to [1:100]
% gives 1000 imaage, because there are 10 luminance levels.
%
% Condition:
% Varaible target reflectance spectrum, Variable illuminant spectra,
% Variable background object reflectnace spectra.
%
% There are two area lights in the base scene and we have inserted one
% additional light. All these have a different relative shape of the power
% spectrum, but are multiplied with the same scale factor in each scene.
%
% 100 images are rendered at 10 equally spaced LRV levels between [0.2 0.6]
%
%
RunToyVirtualWorldRecipes('outputName','Condition3', ...
    'imageWidth',320, ... % Pixel width of rendered image
    'imageHeight',240, ... % Pixel height of rendered image
    'cropImageHalfSize', 25, ... % Half width of the image area aroound the target used for simulating visual response
    'nOtherObjectSurfaceReflectance', 999, ... % Number of random surfaces to choose from
    'luminanceLevels', linspace(0.2,0.6,10), ... % LRV levels
    'reflectanceNumbers',[1:300], ... % Number of images at each LRV level
    'nInsertedLights', 1, ... % Number of inserted lights
    'nInsertObjects', 0, ... % Number of objects inserted in the scene other than target object
    'otherObjectReflectanceRandom', true, ... % Background reflectance spectra, true -> random samples
    'illuminantSpectraRandom', true, ... % Illuminant spectra, true -> random samples
    'minMeanIlluminantLevel', 0.15, ... % Minimum intensity of illuminant
    'maxMeanIlluminantLevel', 150, ... % Maximum intensity of illuminant
    'illuminantScaling', 1, ... % Option to apply intensity scaling in illuminant. 1 -> Scale, 0 -> No scale.
    'lightPositionRandom',false, ... % Fix the position of light source. Only works for a library/bigball case.
    'lightScaleRandom',false, ... % Fix the size of light source.
    'targetPositionRandom',false, ... % Fix the position of target object. Only works for a library/bigball case.
    'targetScaleRandom',false, ... % Fix the size of target object.
    'targetRotationRandom',false, ... % Fix the angular position of target object. No effect for spheres.
    'objectShapeSet',{'BigBall'}, ... % Target object shape
    'lightShapeSet',{'BigBall'}, ... % Inserted light's shape
    'baseSceneSet',{'Library'}, ...  % Base scene
    'mosaicHalfSize', 25, ...        % Half size of cone mosaic. This gives a mosaic of 51*51 cones. (2*25+1 = 51)
    'integrationTime', 100/1000, ... % Light integration time in the cones. (unit: seconds).
    'maxDepth', 10);    % maxDepth = 2 + Number of secondary reflections.
                        % maxDepth = 1: Direct light from the light source.
                        % maxDepth = 2: Light bounced directly off the object. No secondary reflections
                        % maxDepth = N: (N-2) secondary reflections