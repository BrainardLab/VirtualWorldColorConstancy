%% Locate, unpack, and execute many WardLand recipes created earlier.
%
% Use this script to get cone responses.
%
%
% @ingroup WardLand

%% Overall Setup.
clear;
clc;

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
toneMapFactor = 25;
isScale = true;
filterWidth = 7;
lmsSensitivities = 'T_cones_ss2';

% How many annular regions for AMA
nAnnularRegions = 25;

averageResponse=zeros(nAnnularRegions,3);
% easier to read plots
set(0, 'DefaultAxesFontSize', 14)

%% Analyze each packed up recipe.
archiveFiles = FindFiles(recipeFolder, '\.zip$');
nRecipes = numel(archiveFiles);

% Outputs for AMA
allAverageAnnularResponses = zeros(3*nAnnularRegions, nRecipes);
luminanceLevel = zeros(1,nRecipes);
ctgInd = zeros(1,nRecipes);
allLMSResponses = [];
numLMSCones = [];

parfor ii = 1:nRecipes
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

    
    
    
    
    %% Make figure for presentation   
    scene = coneResponse.visualizationInfo.scene;
    oi = coneResponse.visualizationInfo.oi;
    oiRGBnoFilter = coneResponse.visualizationInfo.oiRGBnoFilter;
    oiRGBwithFilter = coneResponse.visualizationInfo.oiRGBwithFilter;
    processingOptions=coneResponse.processingOptions;
    isomerizationsVector=coneResponse.isomerizationsVector;
    coneIndicator=coneResponse.coneIndicator;
    conePositions=coneResponse.conePositions;
    
    hFig = figure(); clf; 
    set(hFig, 'Position', [1 1 1000 1000]);
    
    subplot(3,2,1);
    pathtoImage = fullfile(getpref(projectName, 'workingFolder'),archiveBase,'images','Mitsuba','radiance','normal.mat');
    imageData = parload(pathtoImage);
    [sRGBImage, ~, ~] = MultispectralToSRGB(imageData,[400,10,31],toneMapFactor, isScale);
    srgbUint = uint8(sRGBImage);
    image(srgbUint);
    set(gca,'XTickLabel','');
    set(gca,'YTickLabel','');    

    subplot(3,2,2);
    pathtoImage = fullfile(getpref(projectName, 'workingFolder'),archiveBase,'images','Mitsuba','radiance','mask.mat');
    imageData = parload(pathtoImage);
    [sRGBImage, ~, ~] = MultispectralToSRGB(imageData,[400,10,31],toneMapFactor, isScale);
    image(sRGBImage);
    set(gca,'XTickLabel','');
    set(gca,'YTickLabel','');    
    
    % Show an RGB rendition of the input image
    subplot(3,2,3);
    sceneRGB            = sceneGet(scene, 'RGB image');
    sceneHorizontalFOV  = sceneGet(scene, 'w angular');
    sceneVerticalFOV    = sceneGet(scene, 'h angular');
    sceneSpatialSupport = sceneGet(scene, 'spatial support', 'cm');
    xSceneSpaceInCm     = sceneSpatialSupport(1,:,1);
    ySceneSpaceInCm     = sceneSpatialSupport(:,1,2);
    image(xSceneSpaceInCm, ySceneSpaceInCm, sceneRGB); axis 'image'
    xlabel('space (cm)', 'FontSize', 14); ylabel('space (cm)', 'FontSize', 14); 
    title(sprintf('scene\n(distance: %1.1f meters, %1.2f deg FOV)',processingOptions.distance, processingOptions.horizFOV), 'FontSize', 12, 'FontName', 'Menlo');
    
    % Show an RGB rendition of the optical image
    subplot(3,2,4);
    oiSpatialSupport  = oiGet(oi, 'spatial support', 'microns');
    xOIspaceInRetinalMicrons = squeeze(oiSpatialSupport(1,:,1));
    yOIspaceInRetinalMicrons = squeeze(oiSpatialSupport(:,1,2));
    image(xOIspaceInRetinalMicrons, yOIspaceInRetinalMicrons, oiRGBnoFilter); axis 'image'
    set(gca, 'XLim', [xOIspaceInRetinalMicrons(1) xOIspaceInRetinalMicrons(end)], 'YLim', [yOIspaceInRetinalMicrons(1) yOIspaceInRetinalMicrons(end)]);
    xlabel('space (retinal microns)', 'FontSize', 14); ylabel('space (retinal microns)', 'FontSize', 14); 
    if (processingOptions.skipOTF)
        opticalImageTitle = 'optical image (no OTF)';
    else
        opticalImageTitle = 'optical image (default)';
    end
    title (opticalImageTitle, 'FontSize', 12, 'FontName', 'Menlo');
    
    % Show an RGB rendition of the optical image with the sensor mosaic superimposed 
    subplot(3,2,5);
    image(xOIspaceInRetinalMicrons, yOIspaceInRetinalMicrons, oiRGBwithFilter); axis 'image'; 
    hold on
    % Plot the cone mosaic on top
    conesNum = size(coneIndicator,1);
    for coneIndex = 1:conesNum
        if (coneIndicator(coneIndex,1) == 1)
            % an L-cone
            plot(conePositions(coneIndex,1), conePositions(coneIndex,2), 'rx');
        elseif (coneIndicator(coneIndex,2) == 1)
            % an M-cone
            plot(conePositions(coneIndex,1), conePositions(coneIndex,2), 'gx');
        elseif (coneIndicator(coneIndex,3) == 1)
            % an S-cone
            plot(conePositions(coneIndex,1), conePositions(coneIndex,2), 'bx');
        else
            error('Unknown cone type (%d)\n', coneIndicator(coneIndex,1))
        end
    end
    
    hold off
    set(gca, 'XLim', [xOIspaceInRetinalMicrons(1) xOIspaceInRetinalMicrons(end)], 'YLim', [yOIspaceInRetinalMicrons(1) yOIspaceInRetinalMicrons(end)]);
    xlabel('space (retinal microns)', 'FontSize', 14); ylabel('space (retinal microns)', 'FontSize', 14); 
    title (sprintf('optical image + cone mosaic (%d cones)\n(mosaic half size: %2.0f microns, stride: %d cones)', conesNum, processingOptions.mosaicHalfSize, processingOptions.coneStride), 'FontSize', 12, 'FontName', 'Menlo');
    
    
%     % Show the isomerization map in rows/cols
%     subplot(3,2,5);
%     isomerizationMap = zeros((2*processingOptions.mosaicHalfSize+1)*processingOptions.coneStride, (2*processingOptions.mosaicHalfSize+1)*processingOptions.coneStride);
%     coneIndex = 0;
%     for row = -processingOptions.mosaicHalfSize:processingOptions.mosaicHalfSize
%         rowNo = (processingOptions.mosaicHalfSize+row)*processingOptions.coneStride+1;
%         for col = -processingOptions.mosaicHalfSize:processingOptions.mosaicHalfSize
%             coneIndex = coneIndex + 1;
%             colNo = (processingOptions.mosaicHalfSize+col)*processingOptions.coneStride+1;
%             isomerizationMap(rowNo, colNo) = isomerizationsVector(coneIndex);
%         end
%     end
%     imagesc(1:processingOptions.mosaicHalfSize*2+1, 1:processingOptions.mosaicHalfSize*2+1, isomerizationMap);
%     axis 'image'; colormap(gray(512))
%     set(gca, 'Color', [0 0 0], 'XTick', [], 'YTick', [])
%     set(gca, 'XLim', [0 processingOptions.mosaicHalfSize*2+1+1], ...
%              'YLim', [0. processingOptions.mosaicHalfSize*2+1+1])
%     title('isomerization map (full mosaic)', 'FontSize', 12, 'FontName', 'Menlo')
%  
%     
    % Show the isomerization map in rows/cols
    subplot(3,2,6);
    isomerizationMap = zeros(2*processingOptions.mosaicHalfSize+1, 2*processingOptions.mosaicHalfSize+1);
    coneIndex = 0;
    for row = -processingOptions.mosaicHalfSize:processingOptions.mosaicHalfSize
        rowNo = (processingOptions.mosaicHalfSize+row)+1;
        for col = -processingOptions.mosaicHalfSize:processingOptions.mosaicHalfSize
            coneIndex = coneIndex + 1;
            colNo = (processingOptions.mosaicHalfSize+col)+1;
            isomerizationMap(rowNo, colNo) = isomerizationsVector(coneIndex);
        end
    end
    imagesc(1:processingOptions.mosaicHalfSize*2+1, 1:processingOptions.mosaicHalfSize*2+1, isomerizationMap);
    axis 'image'; colormap(gray(512))
    set(gca, 'Color', [0 0 0], 'XTick', 1:processingOptions.mosaicHalfSize*2+1, 'YTick', 1:processingOptions.mosaicHalfSize*2+1)
    set(gca, 'XLim', [0.5 processingOptions.mosaicHalfSize*2+1+0.5], ...
             'YLim', [0.5 processingOptions.mosaicHalfSize*2+1+0.5])
    xlabel('cone col', 'FontSize', 14); ylabel('cone row', 'FontSize', 14); 
    title('isomerization map (sub-sampled mosaic)', 'FontSize', 12, 'FontName', 'Menlo')
        
    drawnow;
    NicePlot.exportFigToPDF(fullfile([archiveBase,'.pdf']), hFig, 300);
    pathtoAllRenderings=strrep(getpref(projectName, 'workingFolder'),'Working','AllRenderings');
    NicePlot.exportFigToPDF(fullfile(pathtoAllRenderings,[archiveBase,'.pdf']), hFig, 300);
    close(hFig);
end

uniqueLuminaceLevel = unique(luminanceLevel);
for ii = 1: size(unique(luminanceLevel),2)
for jj = 1: size(find(luminanceLevel==uniqueLuminaceLevel(ii)),2)
ctgInd(1,(ii-1)*size(find(luminanceLevel==uniqueLuminaceLevel(ii)),2)+jj)=ii;end
end

save(fullfile(fileparts(getpref(projectName, 'workingFolder')),'stimulusAMA.mat'),...
    'allAverageAnnularResponses','luminanceLevel','ctgInd','numLMSCones','allLMSResponses','allLMSPositions');
