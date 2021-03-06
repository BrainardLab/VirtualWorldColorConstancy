% Steps to run psychophysics 
% Using VirtualWorldColorConstancy
tbUseProject('VirtualWorldColorConstancy');
% 1. Make a database of Images Using Functions RunToyVirtualWorldRecipes
% 2. Make a multispectral struct using testMakeMultispectralStruct
% 
tic;
MakeMultispectralStruct(...
    'folderName','StimuliFixedFlatTargetShapeFixedIlluminantRandomBkGndFixedIntervals_test1',...
    'luminanceLevels', linspace(0.2,0.6,5), ...
    'reflectanceNumbers', (1:20), ...
    'targetShape', 'BigBall', ...
    'baseScene', 'Library', ...
    'cropImageHalfSizeX', 3*25, ...
    'cropImageHalfSizeY', 3*25);
toc

%%
% Using VirtualWorldPsychophysics
tbUseProject('VirtualWorldPsychophysics');

%%
% 3. Convert Multispectral struct to LMS struct
multispectralStructToLMSStruct(...
    'multipsectralStructFolder','StimuliFixedFlatTargetShapeFixedIlluminantRandomBkGndFixedIntervals_test1',...
    'LMSStructFolder','StimuliFixedFlatTargetShapeFixedIlluminantRandomBkGndFixedIntervals_test1',...
    'outputFileName','LMSStruct');

% 4. Make Trial Struct from LMS struct
makeTrialStruct('directoryName','StimuliFixedFlatTargetShapeFixedIlluminantRandomBkGndFixedIntervals_test1',...
    'LMSstructName', 'LMSStruct',...
    'outputFileName', 'StimuliFixedFlatTargetShapeFixedIlluminantRandomBkGndFixedIntervals_test1',...
    'nBlocks', 5,...
    'stdYIndex', 3, ...
    'cmpYIndex', (1:5), ...
    'comparisionTargetSameSpectralShape',true);
% Use testRunLightnessExperiment to run experiment