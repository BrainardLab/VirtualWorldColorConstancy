function ConeResponseToyVirtualWorldRecipes(varargin)
%% Locate, unpack, and execute many WardLand recipes created earlier.
%
% Use this script to get cone responses.
%
%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('outputName','ExampleOutput',@ischar);
parser.addParameter('luminanceLevels', [0.2 0.6], @isnumeric);
parser.addParameter('reflectanceNumbers', [1 2], @isnumeric);
parser.addParameter('mosaicHalfSize', 25, @isnumeric);
parser.addParameter('integrationTime', 100/1000, @isnumeric);
parser.addParameter('cropImageHalfSize', 25, @isnumeric);
parser.addParameter('nRandomRotations', 0, @isnumeric);
parser.addParameter('isomerizationNoise', 'frozen', @ischar);
parser.parse(varargin{:});
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;
mosaicHalfSize = parser.Results.mosaicHalfSize;
integrationTime = parser.Results.integrationTime;
cropImageHalfSize = parser.Results.cropImageHalfSize;
isomerizationNoise = parser.Results.isomerizationNoise;


%% Overall Setup.

% location of packed-up recipes
projectName = 'VirtualWorldColorConstancy';
recipeFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName, 'Originals');
if ~exist(recipeFolder, 'dir')
    disp(['Recipe folder not found: ' recipeFolder]);
end

if ~exist(fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'AllRenderings'),'dir')
    mkdir(fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'AllRenderings'));
end

% location of analysed folder
analysedFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'ConeResponse');

% location of reflectance folder
pathToTargetReflectanceFolder = fullfile(getpref(projectName, 'baseFolder'),...
    parser.Results.outputName,'Data','Reflectances','TargetObjects');

% edit some batch renderer options
hints.renderer = 'Mitsuba';
hints.workingFolder = fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'Working');

% easier to read plots
set(0, 'DefaultAxesFontSize', 14)

%% Analyze each packed up recipe.
archiveFiles = FindToyVirtualWorldRecipes(recipeFolder, luminanceLevels, reflectanceNumbers);
nRecipes = numel(archiveFiles);

% Outputs for AMA
luminanceLevel = zeros(1,nRecipes);
ctgInd = zeros(1,nRecipes);
allLMSResponses = [];
numLMSCones = [];
coneRescalingFactors = [];
allLMSIndicator = [];

parfor ii = 1:nRecipes
    recipe = [];
    try
        % get the recipe
        recipe = rtbUnpackRecipe(archiveFiles{ii}, 'hints', hints);
        rtbChangeToWorkingFolder('hints', recipe.input.hints);
        
        pathToRadianceFile = fullfile(recipe.input.hints.workingFolder,...
            recipe.input.hints.recipeName,'renderings','Mitsuba','normal.mat');
        radiance = parload(pathToRadianceFile);
        wave = 400:10:700;
        
%         factoidFilename = fullfile(recipe.input.hints.workingFolder, ...
%             recipe.input.hints.recipeName,'renderings','Mitsuba','normal-factoids.mat');
%         targetMask = load(factoidFilename);
%         targetObjectIndex = unique(targetMask.factoids.shapeIndex.data(:,:,1)); 
%         isTarget = (targetMask.factoids.shapeIndex.data(:,:,1) == targetObjectIndex(end));
        
        randomSeed = 4343;                       % nan results in new LMS mosaic generation, any other number results in reproducable mosaic
        lowPassFilter = 'matchConeStride';      % 'none' or 'matchConeStride'
        coneResponse = [];
        
        randomAngles = [0 randi(360,1,parser.Results.nRandomRotations)];
        for iterRotations = 1 : length(randomAngles)
            if (iterRotations == 1)
%                 [cR, cC] = findTargetCenter(isTarget); % target center pixel row and column
                cR = floor(size(radiance,1)/2); cC = floor(size(radiance,2)/2); % target center pixel row and column
                croppedImage = radiance(cR-cropImageHalfSize:1:cR+cropImageHalfSize,...
                    cC-cropImageHalfSize:1:cC+cropImageHalfSize,:);
                recipe.processing.croppedImage = croppedImage;
            else
                croppedImage = returnRotatedCroppedImage(isTarget, radiance, ...
                    randomAngles(iterRotations), cropImageHalfSize)
            end
            [coneResponse.isomerizationsVector(:,iterRotations), coneResponse.coneIndicator, coneResponse.conePositions, demosaicedIsomerizationsMaps, isomerizationSRGBrendition, coneMosaicImage, sceneRGBrendition, oiRGBrendition, ...
                coneResponse.processingOptions, coneResponse.visualizationInfo{iterRotations}, coneEfficiencyBasedResponseScalars] = ...
                isomerizationMapFromRadiance(croppedImage, wave, ...
                'meanLuminance', 0, ...                         % mean luminance in c/m2, meanLuminance = 0 means no rescaling
                'horizFOV', 1, ...                              % horizontal field of view in degrees
                'distance', 1.0, ...                            % distance to object in meters
                'coneStride', 3, ...                            % how to sub-sample the full mosaic: stride = 1: full mosaic
                'coneEfficiencyBasedReponseScaling', 'area',... % response scaling, choose one of {'none', 'peak', 'area'} (peak = equal amplitude cone efficiency), (area=equal area cone efficiency)
                'isomerizationNoise', isomerizationNoise, ...   % whether to add isomerization noise or not
                'responseInstances', 1, ...                     % number of response instances to compute (only when isomerizationNoise = true)
                'mosaicHalfSize', mosaicHalfSize, ...           % the subsampled mosaic will have (2*mosaicHalfSize+1)^2 cones
                'integrationTime', integrationTime, ...         % the integration time for the cones
                'lowPassFilter', lowPassFilter,...              % the low-pass filter type to use
                'randomSeed', randomSeed, ...                   % the random seed to use
                'skipOTF', false ...                            % when set to true, we only have diffraction-limited optics
                );
%             coneResponse.demosaicedIsomerizationsMaps{iterRotations} = squeeze(demosaicedIsomerizationsMaps(1,:,:,:));
              coneResponse.demosaicedIsomerizationsMaps(:,iterRotations) = demosaicedIsomerizationsMaps(:);
              
        end
        coneResponse.rotationAngles = randomAngles;
        %% Save Demosaiced response
        allDemosaicResponse(:,ii) = coneResponse.demosaicedIsomerizationsMaps(:);
        %% Find average response for LMS cones in annular regions about the center pixel
        %         averageResponse =  averageAnnularConeResponse(nAnnularRegions, coneResponse);
        %         coneResponse.averageResponse = averageResponse;
        %         allAverageAnnularResponses(:,ii) = averageResponse(:);
        
        coneRescalingFactors(:,ii) = coneEfficiencyBasedResponseScalars;
        coneResponse.coneRescalingFactors = coneEfficiencyBasedResponseScalars;
        %% Find average response in annular regions about the center pixel using demosaiced responses
        %         averageResponseDemosaic =  averageAnnularConeResponseDemosaic(nAnnularRegions, squeeze(demosaicedIsomerizationsMaps(1,:,:,:)));
        %         coneResponse.averageResponseDemosaic = averageResponseDemosaic;
        %         allAverageAnnularResponsesDemosaic(:,ii) = averageResponseDemosaic(:);
        
        %% Represent the LMS response as a vector and save it for AMA
        numLMSCones(ii,:) = sum(coneResponse.coneIndicator);
        allLMSResponses(:,ii) = coneResponse.isomerizationsVector(:);
        allLMSPositions(:,:,ii) = coneResponse.conePositions;
        allLMSIndicator(:,:,ii) = coneResponse.coneIndicator;
        
        %% Save modified recipe
        % save the results in a separate folder
        [archivePath, archiveBase, archiveExt] = fileparts(archiveFiles{ii});
        analysedArchiveFile = fullfile(analysedFolder, [archiveBase archiveExt]);
        
        % Save the luminance levels for AMA
        strTokens = stringTokenizer(archiveBase, '-');
        luminanceLevel(1,ii) = str2double(strrep(strTokens{2},'_','.'));
        coneResponse.luminanceLevel = luminanceLevel(1,ii);
        coneResponse.trueXYZ = calculateTrueXYZ(luminanceLevel(1,ii), ...
            str2double(strTokens{4}), pathToTargetReflectanceFolder);
        
        
        recipe.processing.coneResponse = coneResponse;
        
        tempName=matfile(fullfile(hints.workingFolder,archiveBase,'ConeResponse.mat'),'Writable',true);
        tempName.recipe=recipe;
        excludeFolders = {'temp','images','renderings','resources','scenes'};
        rtbPackUpRecipe(recipe, analysedArchiveFile, 'ignoreFolders', excludeFolders);
        
        %% Make Figures for Visualization
        makeFigureForVisualization(coneResponse,archiveBase,hints.workingFolder);
    catch err
        SaveToyVirutalWorldError(analysedFolder, err, recipe, varargin);
    end
    
end

uniqueLuminaceLevel = unique(luminanceLevel);
for ii = 1: size(unique(luminanceLevel),2)
    for jj = 1: size(find(luminanceLevel==uniqueLuminaceLevel(ii)),2)
        ctgInd(1,(ii-1)*size(find(luminanceLevel==uniqueLuminaceLevel(ii)),2)+jj)=ii;end
end

trueXYZ = calculateTrueXYZ(luminanceLevels, reflectanceNumbers, pathToTargetReflectanceFolder);

%% If there are more cone response vectors for one image due to rotations, 
% the luminancelevel, category index and true XYZ care repeated to match
% the number of cone response vectors produced.

numberOfConeResponseVectors = parser.Results.nRandomRotations+1;
luminanceLevel = repmat(luminanceLevel,numberOfConeResponseVectors,1);
luminanceLevel = (luminanceLevel(:))';
ctgInd = repmat(ctgInd,numberOfConeResponseVectors,1);
ctgInd = (ctgInd(:))';
trueXYZ = reshape(repmat(trueXYZ,numberOfConeResponseVectors,1),[],...
    numberOfConeResponseVectors*size(trueXYZ,2));

% Similarly the allLMSResponse and all demosaic response matrices needs to
% be reshaped
allLMSResponses = reshape(allLMSResponses,[],numberOfConeResponseVectors*size(allLMSResponses,2));
allDemosaicResponse = reshape(allDemosaicResponse,[],numberOfConeResponseVectors*size(allDemosaicResponse,2));

numLMSCones=numLMSCones(1,:);
allLMSPositions=allLMSPositions(:,:,1);
coneRescalingFactors=coneRescalingFactors(:,1);
allLMSIndicator = allLMSIndicator(:,:,1);
% allNNLMS = calculateNearestLMSResponse(numLMSCones,allLMSPositions,allLMSResponses,3);


save(fullfile(getpref(projectName, 'baseFolder'),parser.Results.outputName,'stimulusAMA.mat'),...
    'luminanceLevel','ctgInd','numLMSCones',...
    'allLMSResponses','allLMSPositions','coneRescalingFactors',...
    'allDemosaicResponse','allLMSIndicator','trueXYZ','-v7.3');
