function [theWavelengths, theReflectance, materialName, matteMaterial, wardMaterial] = ...
    computeLuminanceByName(materialNumber, materialName, theLuminanceTarget, hints)
%
% This function takes the material number and target luminanace level and
% returns the scaled reflectance for the given material based on the target
% luminance.
%
% This function takes a RenderToolbox3 "hints" struct which allows it to
% save a scaled spectrum file in the resources folder for the working
% recipe.
%

% Compute the luminance associated with a surface reflectance
% function, and then scale the reflectance to have a desired luminance.

% 3/23/16 vs  wrote it.

% Load in the surface reflectance function associated with whichMaterial
[theWavelengths, theReflectance] = LoadReflectance(materialNumber,theLuminanceTarget);

%% Write a new spectrum file with the scaled reflectance.
resourceFolder = GetWorkingFolder('resources', false, hints);
spectrumFullPath = fullfile(resourceFolder, materialName);
WriteSpectrumFile(theWavelengths, theReflectance, spectrumFullPath);

%% Pack up material descriptions that work with WardLand.
matteMaterial = BuildDesription('material', 'matte', ...
    {'diffuseReflectance'}, ...
    materialName, ...
    {'spectrum'});

% ward material with arbitrary fixed specular component
specularSpectrum = '300:0.5 800:0.5';
wardMaterial = BuildDesription('material', 'anisoward', ...
    {'diffuseReflectance', 'specularReflectance'}, ...
    {materialName, specularSpectrum}, ...
    {'spectrum', 'spectrum'});

