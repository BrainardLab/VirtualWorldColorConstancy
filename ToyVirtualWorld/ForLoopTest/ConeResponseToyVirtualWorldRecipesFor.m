function ConeResponseToyVirtualWorldRecipes(varargin)
%% Locate, unpack, and execute many WardLand recipes created earlier.
%
% Use this script to get cone responses.
%
%% Get inputs and defaults.
parser = inputParser();
parser.addParameter('luminanceLevels', [], @isnumeric);
parser.addParameter('reflectanceNumbers', [], @isnumeric);
parser.addParameter('nAnnularRegions', 25, @isnumeric);
parser.parse(varargin{:});
luminanceLevels = parser.Results.luminanceLevels;
reflectanceNumbers = parser.Results.reflectanceNumbers;
nAnnularRegions = parser.Results.nAnnularRegions;
%% Overall Setup.

% location of packed-up recipes
projectName = 'ToyVirtualWorld';
recipeFolder = fullfile(getpref(projectName, 'recipesFolder'), 'Analysed');
if ~exist(recipeFolder, 'dir')
    disp(['Recipe folder not found: ' recipeFolder]);
end

if ~exist(strrep(getpref(projectName, 'workingFolder'),'Working','AllRenderings'),'dir')
    mkdir(strrep(getpref(projectName, 'workingFolder'),'Working','AllRenderings'));
end

% location of saved figures
figureFolder = fullfile(getpref(projectName, 'recipesFolder'), 'Figures');

% location of analysed folder
analysedFolder = fullfile(getpref(projectName, 'recipesFolder'),'ConeResponse');

% edit some batch renderer options
hints.renderer = 'Mitsuba';
hints.workingFolder = getpref(projectName, 'workingFolder');

% analysis params
toneMapFactor = 10;
isScale = true;
filterWidth = 7;
lmsSensitivities = 'T_cones_ss2';

% easier to read plots
set(0, 'DefaultAxesFontSize', 14)

%% Analyze each packed up recipe.
archiveFiles = FindToyVirtualWorldRecipes(recipeFolder, luminanceLevels, reflectanceNumbers);
nRecipes = numel(archiveFiles);

% Outputs for AMA
allAverageAnnularResponses = zeros(3*nAnnularRegions, nRecipes);
luminanceLevel = zeros(1,nRecipes);
ctgInd = zeros(1,nRecipes);
allLMSResponses = [];
numLMSCones = [];

for ii = 1:nRecipes
    recipe = [];
    try
        % get the recipe
        recipe = rtbUnpackRecipe(archiveFiles{ii}, 'hints', hints);
        ChangeToWorkingFolder(recipe.input.hints);
    
        radiance = recipe.processing.target.croppedImage;
        wave = 400:10:700;
    
        randomSeed = 1234;                       % nan results in new LMS mosaic generation, any other number results in reproducable mosaic
        lowPassFilter = 'matchConeStride';      % 'none' or 'matchConeStride'
    
        coneResponse = [];
        [coneResponse.isomerizationsVector, coneResponse.coneIndicator, coneResponse.conePositions,...
        coneResponse.processingOptions, coneResponse.visualizationInfo] = ...
        isomerizationMapFromRadiance(radiance, wave, ...
            'meanLuminance', 500, ...           % mean luminance in c/m2
            'horizFOV', 1, ...                  % horizontal field of view in degrees
            'distance', 1.0, ...                % distance to object in meters
            'coneStride', 3, ...               % how to sub-sample the full mosaic: stride = 1: full mosaic
            'mosaicHalfSize', 25, ...            % the subsampled mosaic will have (2*mosaicHalfSize+1)^2 cones
            'lowPassFilter', lowPassFilter,...  % the low-pass filter type to use
            'randomSeed', randomSeed ...        % the random seed to use
            );

%% Find average response for LMS cones in annular regions about the center pixel
        averageResponse =  averageAnnularConeResponse(nAnnularRegions, coneResponse);
        coneResponse.averageResponse = averageResponse;
        allAverageAnnularResponses(:,ii) = averageResponse(:);
    
%% Represent the LMS response as a vector and save it for AMA    
        numLMSCones(ii,:) = sum(coneResponse.coneIndicator);
        [LMSResponseVector, LMSPositions] = ConeResponseVectorAMA(coneResponse);
        allLMSResponses(:,ii) = LMSResponseVector;
        allLMSPositions(:,:,ii) = LMSPositions;
    
%% Save modified recipe 
        recipe.processing.coneResponse = coneResponse;

%% Save the luminance levels for AMA
        strTokens = stringTokenizer(recipe.input.conditionsFile, '-');
        luminanceLevel(1,ii) = str2double(strrep(strTokens{2},'_','.'));
    
        % save the results in a separate folder
        [archivePath, archiveBase, archiveExt] = fileparts(archiveFiles{ii});
        analysedArchiveFile = fullfile(analysedFolder, [archiveBase archiveExt]);
        tempName=matfile(fullfile(getpref(projectName, 'workingFolder'),archiveBase,'ConeResponse.mat'),'Writable',true);
        tempName.coneResponse=coneResponse;
        excludeFolders = {'temp','images','renderings','resources','scenes'};
        rtbPackUpRecipe(recipe, analysedArchiveFile, 'ignoreFolders', excludeFolders);
    
%% Make Figures for Visualization
        makeFigureForVisualization(coneResponse,projectName,archiveBase);
    catch err
        SaveToyVirutalWorldError(analysedFolder, err, recipe, varargin);
    end
        
end

uniqueLuminaceLevel = unique(luminanceLevel);
for ii = 1: size(unique(luminanceLevel),2)
for jj = 1: size(find(luminanceLevel==uniqueLuminaceLevel(ii)),2)
ctgInd(1,(ii-1)*size(find(luminanceLevel==uniqueLuminaceLevel(ii)),2)+jj)=ii;end
end

numLMSCones=numLMSCones(1,:);
allLMSPositions=allLMSPositions(:,:,1);

allNNLMS = calculateNearestLMSResponse(numLMSCones,allLMSPositions,allLMSResponses,3);

save(fullfile(fileparts(getpref(projectName, 'workingFolder')),'stimulusAMA.mat'),...
                'allAverageAnnularResponses','luminanceLevel','ctgInd','numLMSCones',...
            'allNNLMS','allLMSResponses','allLMSPositions');
