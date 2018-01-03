function Run1000TestScenes
%Run1000TestScenes
%
% Usage: 
%     Run1000TestScenes
%
% Description:
%     Use the VWCC environment to generate 1000 test scenes. Parameters are
%     defined below. The detailed parameters are in the function 
%     RunToyVirtualWorldRecipes.
%
% Input:
%    None
%
% Output:
%    The scene and image data is written into the output directory.
%
% Parameters used
%   outputName - Output filename where recipes will be stored
%   imageWidth - width of image in pixels
%   imageHeight - height of image in pixels
%   cropImageHalfSize - half size of cropped image in pixels
%   nOtherObjectSurfaceReflectance - Number of random surfaces to choose from
%   luminanceLevels - luminance levels of the target object
%   reflectanceNumbers - indices used to specify reflectnace of target
%               obejct reflectance
%   nInsertedLights - number of light source inserted in the image
%   nInsertObjects - number of obejcts inserted in the image (other than target)
%   otherObjectReflectanceRandom - boolean to specify if the background
%                   reflectances are random from image to image. Default
%                   true
%   illuminantSpectraRandom - boolean to specify if the illuminant spectrum
%                   are random from image to image. Default is true
%   illuminantSpectrumNotFlat- boolean to specify if the illuminant
%                   spectrum is flat. Default true, = is not flat
%   targetSpectrumNotFlat - boolean to specify if the target reflectance
%                   spectrum is flat. Default true = is not flat
%   lightPositionRandom - position of inserted light, default false = fixed
%   lightScaleRandom - scale of inserted light, default false = fixed
%   targetPositionRandom - position of target object, default false = fixed
%   targetScaleRandom - scale of inserted light, default false = fixed
%   targetRotationRandom - Target object 3D rotaional pose fixed or not
%   objectShapeSet - shape of inserted object to be used as inserted objects
%   lightShapeSet - shape of inserted object to be used as inserted lights
%   baseSceneSet- base scene set
%   mosaicHalfSize - half size of cone mosaic, total size = 2*mosaicHalfSize +1
%   nRandomRotations - number of random rotations applied to get cone
%       responses. These are in addition to the response at 0 degree

% 07/08/17  dhb  Added a header comment, as far as I could.
%           dhb  Change name to match conventions of this project.
% 07/09/17  VS   Added more comments

RunToyVirtualWorldRecipes('outputName','Set2Images1000Rotations10',...
    'imageWidth',320,...
    'imageHeight',240,...
    'cropImageHalfSize', 25, ...
    'nOtherObjectSurfaceReflectance', 999, ... % Number of random surfaces to choose from
    'luminanceLevels',(0.2:0.4/9:0.6),... 
    'reflectanceNumbers',(1:5),...
    'nInsertedLights', 1, ...
    'nInsertObjects', 0, ... % These are objects other than target objects
    'otherObjectReflectanceRandom',true,...
    'illuminantSpectraRandom',true,...
    'illuminantSpectrumNotFlat',true,...
    'minMeanIlluminantLevel', 5, ...
    'maxMeanIlluminantLevel', 5, ...
    'targetSpectrumNotFlat',true,...    
    'allTargetSpectrumSameShape', false, ...
    'targetReflectanceScaledCopies', false, ...
    'lightPositionRandom',false,...
    'lightScaleRandom',false,...
    'targetPositionRandom',false,...
    'targetScaleRandom',false,...
    'targetRotationRandom',false, ...
    'objectShapeSet',{'BigBall'},...
    'lightShapeSet',{'BigBall'}, ...
    'baseSceneSet',{'Library'},...    
    'mosaicHalfSize', 25, ...
    'nRandomRotations', 10);
