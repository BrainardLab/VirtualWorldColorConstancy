function [isomerizationsVector, coneIndicator, conePositions, processingOptions, visualizationInfo] = ...
    isomerizationMapFromRadiance(radiance, wave, varargin)
 
    % default parameters
    defaultMeanLuminance = 200;
    defaultHorizFOV = 1.0;
    defaultDistance = 1.0;
    
    defaultConeLMSdensities = [0.6 0.3 0.1];
    defaultMosaicHalfSize = 5; 
    defaultConeStride = 15;
    defaultLowPassFilter = 'none';
    defaultRandomSeed =  242352352;
    defaultSkipOTF = false;
    
    % parse the input for parameter modifiers
    parser = inputParser;
    parser.addParamValue('meanLuminance',   defaultMeanLuminance,   @isnumeric);
    parser.addParamValue('horizFOV',        defaultHorizFOV,        @isnumeric);
    parser.addParamValue('distance',        defaultDistance,        @isnumeric);
    parser.addParamValue('mosaicHalfSize',  defaultMosaicHalfSize,  @isnumeric);
    parser.addParamValue('coneLMSdensities', defaultConeLMSdensities, @isvector);
    parser.addParamValue('coneStride',      defaultConeStride,      @isnumeric);
    parser.addParamValue('lowPassFilter',   defaultLowPassFilter,   @ischar);
    parser.addParamValue('randomSeed',      defaultRandomSeed,      @isnumeric);
    parser.addParamValue('skipOTF',         defaultSkipOTF,         @islogical);
    
    % Execute the parser to make sure input is good
    parser.parse(varargin{:});
    pNames = fieldnames(parser.Results);
    for k = 1:length(pNames)
       p.(pNames{k}) = parser.Results.(pNames{k});
       if (isempty(p.(pNames{k})))
           error('Required input argument ''%s'' was not passed', p.(pNames{k}));
       end
    end
 
    % Take care of randomness
    if (isnan(p.randomSeed))
       rng('shuffle');   % produce different random numbers
    else
       rng(p.randomSeed);
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
    
    
    % Create human sensor
    sensor = sensorCreate('human');
    
    % Set sensor size
    sensor = sensorSet(sensor, 'size', (p.coneStride*(2*p.mosaicHalfSize)+1)*[1 1]);
    
    % Set LMS densities
    sensor = sensorSet(sensor, 'densities', cat(2, 0, p.coneLMSdensities));
    
    % Subsample the mosaic
    coneTypes = sensorGet(sensor, 'cone type');
    % make all cones null
    subSampledMosaic = ones(2*p.mosaicHalfSize+1,2*p.mosaicHalfSize+1);
    coneIndex = 0;
    for row = -p.mosaicHalfSize:p.mosaicHalfSize
        for col = -p.mosaicHalfSize:p.mosaicHalfSize
            coneIndex = coneIndex + 1;
            subSampledMosaic((p.mosaicHalfSize+row)*p.coneStride+1, (p.mosaicHalfSize+col)*p.coneStride+1) = coneTypes(coneIndex);
        end
    end
    sensor = sensorSet(sensor, 'cone type', subSampledMosaic);
    
    % Compute cone isomerizations
    sensor = coneAbsorptions(sensor, oi);
    
    % Extract the isomerization map
    fullIsomerizationMap = sensorGet(sensor, 'photon rate');
    
    
    % Compute returned parameters
    sensorSpatialSupport = sensorGet(sensor, 'spatial support', 'microns');
    coneTypes = sensorGet(sensor, 'cone type');
    keptConesNum = (2*p.mosaicHalfSize+1)^2;
    
    isomerizationsVector = zeros(keptConesNum,1);
    coneIndicator = zeros(keptConesNum,3);
    conePositions = zeros(keptConesNum,2);
    
    coneIndex = 0;
    for row = -p.mosaicHalfSize:p.mosaicHalfSize
        rowNo = (p.mosaicHalfSize+row)*p.coneStride+1;
        for col = -p.mosaicHalfSize:p.mosaicHalfSize
            coneIndex = coneIndex + 1;
            colNo = (p.mosaicHalfSize+col)*p.coneStride+1;
            isomerizationsVector(coneIndex) = fullIsomerizationMap(rowNo, colNo);
            conePositions(coneIndex,1) = sensorSpatialSupport.x(1, colNo);
            conePositions(coneIndex,2) = sensorSpatialSupport.y(1, rowNo);
            switch (coneTypes(rowNo, colNo))
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