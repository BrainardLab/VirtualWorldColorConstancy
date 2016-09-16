function [isomerizationsVector, coneIndicator, conePositions, processingOptions, visualizationInfo, varargout] = ...
    isomerizationMapFromRadiance(radiance, wave, varargin)
 
    % default parameters
    defaultMeanLuminance = 200;
    defaultHorizFOV = 1.0;
    defaultDistance = 1.0;
    
    defaultConeLMSdensities = [0.6 0.3 0.1];
    defaultConeEfficiencyBasedReponseScaling = 'none';
    defaultIsomerizationNoise = false;
    defaultResponseInstances = 1;
    defaultMosaicHalfSize = 5; 
    defaultConeStride = 15;
    defaultLowPassFilter = 'none';
    defaultRandomSeed =  242352352;
    defaultSkipOTF = false;
    
    % parse the input for parameter modifiers
    parser = inputParser;
    parser.addParamValue('meanLuminance',                       defaultMeanLuminance,                       @isnumeric);
    parser.addParamValue('horizFOV',                            defaultHorizFOV,                            @isnumeric);
    parser.addParamValue('distance',                            defaultDistance,                            @isnumeric);
    parser.addParamValue('mosaicHalfSize',                      defaultMosaicHalfSize,                      @isnumeric);
    parser.addParamValue('coneLMSdensities',                    defaultConeLMSdensities,                    @isvector);
    parser.addParamValue('coneEfficiencyBasedReponseScaling',   defaultConeEfficiencyBasedReponseScaling,   @ischar);
    parser.addParamValue('isomerizationNoise',                  defaultIsomerizationNoise,                  @islogical);
    parser.addParamValue('responseInstances',                   defaultResponseInstances,                   @isnumeric);
    parser.addParamValue('coneStride',                          defaultConeStride,                          @isnumeric);
    parser.addParamValue('lowPassFilter',                       defaultLowPassFilter,                       @ischar);
    parser.addParamValue('randomSeed',                          defaultRandomSeed,                          @isnumeric);
    parser.addParamValue('skipOTF',                             defaultSkipOTF,                             @islogical);
    
    % Execute the parser to make sure input is good
    parser.parse(varargin{:});
    pNames = fieldnames(parser.Results);
    for k = 1:length(pNames)
       p.(pNames{k}) = parser.Results.(pNames{k});
       if (isempty(p.(pNames{k})))
           error('Required input argument ''%s'' was not passed', p.(pNames{k}));
       end
    end
 
    if (p.isomerizationNoise == false)
        p.responseInstances = 1;
    end
    
    % Take care of randomness
    if (isnan(p.randomSeed))
       rng('shuffle');   % produce different random numbers
    else
       rng(p.randomSeed);
    end
    
    % Check that the coneEfficiencyBasedReponseScaling has a valid value
    if (~ismember(p.coneEfficiencyBasedReponseScaling, {'none', 'peak', 'area'}))
        error('''coneEfficiencyBasedReponseScaling'' must be one of the following: ''none'', ''peak'', ''area'' \n');
    end
    
    % Create scene object
    scene = sceneCreate('multispectral');
    
    % Set the spectal sampling
    scene = sceneSet(scene,'wave', wave);
    
    % Set the scene radiance (in photons/steradian/m^2/nm)
    scene = sceneSet(scene,'photons', Energy2Quanta(wave, radiance));
    
    % Set the scene's illuminant (assume D65 daylight illuminant)
    scene = sceneSet(scene,'illuminant',illuminantCreate('d65', wave));
    
    % Adjust scene parameters
    % 1. Set the mean luminance
    scene = sceneAdjustLuminance(scene, p.meanLuminance);
    
    % 2. Set the horizontal FOV
    scene = sceneSet(scene, 'wAngular', p.horizFOV);
    
    % 3. Set the scene distance
    scene = sceneSet(scene, 'distance', p.distance);
    
    % Generate human optics
    oi = oiCreate('human');
    
    % Adjust optics
    if (p.skipOTF)
        % Get the optics
        optics = oiGet(oi, 'optics');
        % no OTF
        optics = opticsSet(optics, 'model', 'diffraction limited');
        % set back the customized optics
        oi = oiSet(oi,'optics', optics);
    end
    
    % Compute the optical image
    oi = oiCompute(oi, scene);
    
    % Low pass the optical image (if so specified)
    oiRGBnoFilter = oiGet(oi, 'RGB image');
    oiRGBwithFilter = oiRGBnoFilter;
    if (strcmp(p.lowPassFilter, 'matchConeStride'))
        filterWidth = p.coneStride;
        lpFilter = generateLowPassFilter(p.coneStride, filterWidth);
        radianceData = oiGet(oi, 'photons');
        for bandNo = 1:size(radianceData,3)
            radianceSlice = radianceData(:,:, bandNo);
            radianceSlice = conv2(radianceSlice, lpFilter, 'same');
            radianceData(:,:, bandNo) = radianceSlice;
        end
        oi = oiSet(oi, 'photons', radianceData);
        % add the filter on the top-left corner
        oiRGBwithFilter = oiGet(oi, 'RGB image');
        oiRGBwithFilter(1:size(lpFilter,1), 1:size(lpFilter,2),1) = lpFilter / max(lpFilter(:));
        oiRGBwithFilter(1:size(lpFilter,1), 1:size(lpFilter,2),2) = oiRGBwithFilter(1:size(lpFilter,1), 1:size(lpFilter,2),1);
        oiRGBwithFilter(1:size(lpFilter,1), 1:size(lpFilter,2),3) = oiRGBwithFilter(1:size(lpFilter,1), 1:size(lpFilter,2),1);
        
    elseif (strcmp(p.lowPassFilter, 'none'))
        ; % do nothing
    else
        error('Unknown option for lowpass filter ''%s''.', p.lowPassFilter)
    end
    
    
    % Create human cone mosaic
    humanConeMosaic = coneMosaic;
    desiredMosaicFOVinMeters = ((2*p.mosaicHalfSize)* p.coneStride+1) * humanConeMosaic.pigment.width;
    desiredMosaicFOVinDeg = desiredMosaicFOVinMeters * humanConeMosaic.fov(1)/humanConeMosaic.width;
    humanConeMosaic.setSizeToFOV(desiredMosaicFOVinDeg);
    humanConeMosaic.noiseFlag = p.isomerizationNoise;
    
    % Subsample the mosaic pattern
    subSampledPattern = ones(2*p.mosaicHalfSize+1,2*p.mosaicHalfSize+1);
    coneIndex = 0;
    for row = -p.mosaicHalfSize:p.mosaicHalfSize
        for col = -p.mosaicHalfSize:p.mosaicHalfSize
            coneIndex = coneIndex + 1;
            subSampledPattern((p.mosaicHalfSize+row)*p.coneStride+1, (p.mosaicHalfSize+col)*p.coneStride+1) = humanConeMosaic.pattern(coneIndex);
        end
    end
    humanConeMosaic.pattern = subSampledPattern;
    
    
    % Compute the isomerization maps
    if (p.isomerizationNoise) && (p.responseInstances > 1)
        for responseInstanceIndex = 1:p.responseInstances
            if (responseInstanceIndex == 1)
                tmp = humanConeMosaic.compute(oi,'currentFlag',false);
                fullIsomerizationMap = zeros(p.responseInstances, size(tmp,1), size(tmp,2));
                fullIsomerizationMap(1,:,:) = tmp;
            else
                fullIsomerizationMap(responseInstanceIndex,:,:) = humanConeMosaic.compute(oi,'currentFlag',false);
            end
        end
    else
        fullIsomerizationMap(1,:,:) = humanConeMosaic.compute(oi,'currentFlag',false);
    end
    
    % Check whether the user asked to scale the isomerization responses
    if (~strcmp(p.coneEfficiencyBasedReponseScaling, 'none'))
        fprintf('Scaling responses to simulate equal quantal efficiencies for L,M and S cones.\n');
        
        % Compute the quantal cone efficiency for each cone at the cornea (i.e., after adding the lens filter, macular filter already included in humanConeMosaic.qe).
        lensTransmittance = lensGet(Lens(),'transmittance');
        cornealQuantalEfficiencies = bsxfun(@times, humanConeMosaic.qe, lensTransmittance);

        % Compute the response scalars
        if strcmp(p.coneEfficiencyBasedReponseScaling, 'peak')
            % normalize for amplitude of quantal efficiency curves
            scalarsToEqualizeCornealQuantalEfficiencies = 1./max(cornealQuantalEfficiencies, [], 1);
        elseif strcmp(p.coneEfficiencyBasedReponseScaling, 'area')
            % normalize for area of quantal efficiency curves
            scalarsToEqualizeCornealQuantalEfficiencies = 1./sum(cornealQuantalEfficiencies, 1);
        end
        
        scalarsToEqualizeCornealQuantalEfficiencies = scalarsToEqualizeCornealQuantalEfficiencies / scalarsToEqualizeCornealQuantalEfficiencies(1);
        varargout{1} = scalarsToEqualizeCornealQuantalEfficiencies;
        
        
        % Compute cone indices in the mosaic
        for coneType = 1:3
            coneIndices{coneType} = find(humanConeMosaic.pattern == coneType+1);
        end
        
        % Apply the response scalars
        for k = 1:p.responseInstances
            frame = squeeze(fullIsomerizationMap(k,:,:));
            for coneType = 1:3
                frame(coneIndices{coneType}) = frame(coneIndices{coneType}) * scalarsToEqualizeCornealQuantalEfficiencies(coneType);
            end
            fullIsomerizationMap(k,:,:) = frame;
        end
    else
        varargout{1} = [];
    end
    
    
    % Compute returned parameters
    keptConesNum = (2*p.mosaicHalfSize+1)^2;
    isomerizationsVector = zeros(keptConesNum,p.responseInstances);
    coneIndicator = zeros(keptConesNum,3);
    conePositions = zeros(keptConesNum,2);
    
    coneIndex = 0;
    for row = -p.mosaicHalfSize:p.mosaicHalfSize
        rowNo = (p.mosaicHalfSize+row)*p.coneStride+1;
        for col = -p.mosaicHalfSize:p.mosaicHalfSize
            coneIndex = coneIndex + 1;
            colNo = (p.mosaicHalfSize+col)*p.coneStride+1;
            
            for responseInstanceIndex = 1:p.responseInstances
                isomerizationsVector(coneIndex, responseInstanceIndex) = fullIsomerizationMap(responseInstanceIndex,rowNo, colNo);
            end
            
            conePositions(coneIndex,1) = humanConeMosaic.patternSupport(rowNo, colNo, 1)*1e6;
            conePositions(coneIndex,2) = humanConeMosaic.patternSupport(rowNo, colNo, 2)*1e6;
            switch (humanConeMosaic.pattern(rowNo, colNo))
                case 2 
                    coneIndicator(coneIndex,1) = 1;
                case 3 
                    coneIndicator(coneIndex,2) = 1;
                case 4 
                    coneIndicator(coneIndex,3) = 1;
            end
        end
    end
    
    
    % The processing options
    processingOptions = p; 
    
    % Visualization info
    visualizationInfo = struct(...
        'scene', scene, ...
        'oi', oi,...
        'oiRGBnoFilter', oiRGBnoFilter, ...
        'oiRGBwithFilter', oiRGBwithFilter...
        );
    
end