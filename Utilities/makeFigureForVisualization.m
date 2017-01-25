function makeFigureForVisualization(coneResponse,projectName,archiveBase,workingFolder)

% analysis params
toneMapFactor = 10;
isScale = true;
filterWidth = 7;
lmsSensitivities = 'T_cones_ss2';


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

        % Plot the RGB rendition of the image
        subplot(3,2,1);
        pathtoImage = fullfile(workingFolder,archiveBase,'images','Mitsuba','radiance','normal.mat');
        imageData = parload(pathtoImage);
        [sRGBImage, ~, ~] = rtbMultispectralToSRGB(imageData,[400,10,31], 'toneMapFactor', toneMapFactor, 'isScale', isScale);
        srgbUint = uint8(sRGBImage);
        image(srgbUint);
        title(archiveBase);
        set(gca,'XTickLabel','');
        set(gca,'YTickLabel','');    

        % Plot the mask image
        subplot(3,2,2);
        pathtoImage = fullfile(workingFolder,archiveBase,'images','Mitsuba','radiance','mask.mat');
        imageData = parload(pathtoImage);
        [sRGBImage, ~, ~] = rtbMultispectralToSRGB(imageData,[400,10,31], 'toneMapFactor', toneMapFactor, 'isScale', isScale);
        image(sRGBImage);
        set(gca,'XTickLabel','');
        set(gca,'YTickLabel','');    
    
        % Show an RGB rendition of the cropped part
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
        
        
%             % Show the isomerization map in rows/cols
%             subplot(3,2,5);
%             isomerizationMap = zeros((2*processingOptions.mosaicHalfSize+1)*processingOptions.coneStride, (2*processingOptions.mosaicHalfSize+1)*processingOptions.coneStride);
%             coneIndex = 0;
%             for row = -processingOptions.mosaicHalfSize:processingOptions.mosaicHalfSize
%                 rowNo = (processingOptions.mosaicHalfSize+row)*processingOptions.coneStride+1;
%                 for col = -processingOptions.mosaicHalfSize:processingOptions.mosaicHalfSize
%                     coneIndex = coneIndex + 1;
%                     colNo = (processingOptions.mosaicHalfSize+col)*processingOptions.coneStride+1;
%                     isomerizationMap(rowNo, colNo) = isomerizationsVector(coneIndex);
%                 end
%             end
%             imagesc(1:processingOptions.mosaicHalfSize*2+1, 1:processingOptions.mosaicHalfSize*2+1, isomerizationMap);
%             axis 'image'; colormap(gray(512))
%             set(gca, 'Color', [0 0 0], 'XTick', [], 'YTick', [])
%             set(gca, 'XLim', [0 processingOptions.mosaicHalfSize*2+1+1], ...
%                      'YLim', [0. processingOptions.mosaicHalfSize*2+1+1])
%             title('isomerization map (full mosaic)', 'FontSize', 12, 'FontName', 'Menlo')
%         
        
%         Show the isomerization map in rows/cols
%         subplot(3,2,6);
%         isomerizationMap = zeros(2*processingOptions.mosaicHalfSize+1, 2*processingOptions.mosaicHalfSize+1);
%         coneIndex = 0;
%         for row = -processingOptions.mosaicHalfSize:processingOptions.mosaicHalfSize
%             rowNo = (processingOptions.mosaicHalfSize+row)+1;
%             for col = -processingOptions.mosaicHalfSize:processingOptions.mosaicHalfSize
%                 coneIndex = coneIndex + 1;
%                 colNo = (processingOptions.mosaicHalfSize+col)+1;
%                 isomerizationMap(rowNo, colNo) = isomerizationsVector(coneIndex);
%             end
%         end
%         imagesc(1:processingOptions.mosaicHalfSize*2+1, 1:processingOptions.mosaicHalfSize*2+1, isomerizationMap);
%         axis 'image'; colormap(gray(512))
%         set(gca, 'Color', [0 0 0], 'XTick', 1:processingOptions.mosaicHalfSize*2+1, 'YTick', 1:processingOptions.mosaicHalfSize*2+1)
%         set(gca, 'XLim', [0.5 processingOptions.mosaicHalfSize*2+1+0.5], ...
%             'YLim', [0.5 processingOptions.mosaicHalfSize*2+1+0.5])
%         xlabel('cone col', 'FontSize', 14); ylabel('cone row', 'FontSize', 14);
%         title('isomerization map (sub-sampled mosaic)', 'FontSize', 12, 'FontName', 'Menlo')
%         
        

        subplot(3,2,6);
%         normConeResponse = bsxfun(@rdivide,coneResponse.averageResponse,max(coneResponse.averageResponse));
        hold on;
        plot(coneResponse.averageResponseDemosaic(:,1),'r');
        plot(coneResponse.averageResponseDemosaic(:,2),'g');
        plot(coneResponse.averageResponseDemosaic(:,3),'b');
        title('Normalised Average Annular Cone Response', 'FontSize', 12, 'FontName', 'Menlo');
        xlabel('Annular region Number', 'FontSize', 14); ylabel('Normalised Response', 'FontSize', 14);
        
        drawnow;
        NicePlot.exportFigToPDF(fullfile([archiveBase,'.pdf']), hFig, 300);
%         pathtoAllRenderings=strrep(getpref(projectName, 'workingFolder'),'Working','AllRenderings');
%         NicePlot.exportFigToPDF(fullfile(pathtoAllRenderings,[archiveBase,'.pdf']), hFig, 300);
        close(hFig);