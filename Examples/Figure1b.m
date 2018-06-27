% Make Figure 1b/Figure5a in the paper
% 
% This script is similar to Condition1.m
% We have changed the option so that only 5 images are rendered per level.
% We have used only three levels [0.2 0.4 0.6]
% Further the target reflectances relative spectrum are chosen to be the
% same shape as in figure 1b. This is done through the option
% targetReflectanceScaledCopies.
%
% Finally the cropped image montage is made through the funciton
% makeCroppedImageMontage
%
% The cropped image montage will be saved in the folder Figure1b.
%
%
RunToyVirtualWorldRecipes('outputName','Figure1b', ...
    'imageWidth',320, ... % Pixel width of rendered image
    'imageHeight',240, ... % Pixel height of rendered image
    'cropImageHalfSize', 25, ... % Half width of the image area aroound the target used for simulating visual response
    'nOtherObjectSurfaceReflectance', 999, ... % Number of random surfaces to choose from
    'luminanceLevels', linspace(0.2,0.6,3), ... % LRV levels
    'reflectanceNumbers',[1:5], ... % Number of images at each LRV level
    'nInsertedLights', 1, ... % Number of inserted lights
    'nInsertObjects', 0, ... % Number of objects inserted in the scene other than target object
    'otherObjectReflectanceRandom', false, ... % Background reflectance spectra, false -> fixed
    'illuminantSpectraRandom', false, ... % Illuminant spectra, false -> fixed
    'targetReflectanceScaledCopies',true, ...
    'minMeanIlluminantLevel', 0.15, ... % Minimum intensity of illuminant
    'maxMeanIlluminantLevel', 150, ... % Maximum intensity of illuminant
    'illuminantScaling', 1, ... % Option to apply intensity scaling in illuminant. 1 -> Scale, 0 -> No scale
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
                        
    makeCroppedImageMontage('Figure1b',[0.2 0.4 0.6], [1:5],0.005);