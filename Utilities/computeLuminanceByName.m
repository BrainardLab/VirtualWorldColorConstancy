function [theWavelengths, theReflectance, materialName, matteMaterial, wardMaterial] = ...
    computeLuminanceByName( materialName, theLuminanceTarget, hints)
%
% This function takes the material number and target luminanace level and
% read the file with these parameters saved in the Reflectances/TargetObjects
% folder.
%
% This function takes a RenderToolbox3 "hints" struct which allows it to
% save a scaled spectrum file in the resources folder for the working
% recipe.
%

% Compute the luminance associated with a surface reflectance
% function, and then scale the reflectance to have a desired luminance.

% 3/23/16 vs  wrote it.

% Load in the surface reflectance function associated with whichMaterial
[theWavelengths, theReflectance] = LoadReflectanceByName(materialName, theLuminanceTarget, hints);

%% Write a new spectrum file with the scaled reflectance.
resourceFolder = rtbWorkingFolder('folder','resources', 'hints', hints);
spectrumFullPath = fullfile(resourceFolder, materialName);
rtbWriteSpectrumFile(theWavelengths, theReflectance, spectrumFullPath);

%% Pack up material descriptions that work with WardLand.
matteMaterial = rtbBuildDesription('material', 'matte', ...
    {'diffuseReflectance', 'ensureEnergyConservation'}, ...
    {materialName, 'false'}, ...
    {'spectrum', 'boolean'});

% ward material with arbitrary fixed specular component
specularSpectrum = '300:0.5 800:0.5';
wardMaterial = rtbBuildDesription('material', 'anisoward', ...
    {'diffuseReflectance', 'specularReflectance', 'ensureEnergyConservation'}, ...
    {materialName, specularSpectrum, 'false'}, ...
    {'spectrum', 'spectrum', 'boolean'});

