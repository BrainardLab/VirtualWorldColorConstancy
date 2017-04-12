function trueXYZ = calculateTrueXYZ(luminanceLevels, reflectanceNumbers, pathToTargetReflectanceFolder)

% This function calcualtes the XYZ co ordiantes of the target material 
% given the luminance level and the reflectance number. 
% The corresponding file is read from the 
% VirtualWorldColorConstancy/Resources/Reflectance folder and
% the hue under standard D65 illumination is returned.
%
% trueHue = calculateTrueXYZ(0.4, 501, );
%
% 04/06/2017    VS wrote it
trueXYZ = zeros(3,length(luminanceLevels)*length(reflectanceNumbers));

for ii = 1:length(luminanceLevels)
    for jj = 1:length(reflectanceNumbers)
        
        %% Load in the reflectance function for the given recipe conditions
        reflectanceFileName = sprintf('luminance-%.4f-reflectance-%03d.spd', ...
                luminanceLevels(ii), reflectanceNumbers(jj));
        fileName = fullfile(pathToTargetReflectanceFolder, reflectanceFileName);
        [theWavelengths, theReflectance] = rtbReadSpectrum(fileName);

        %% Load in spectral weighting function for luminance
        % This is the 1931 CIE standard
        theXYZData = load('T_xyz1931');
        theXYZCMFs = SplineCmf(theXYZData.S_xyz1931,theXYZData.T_xyz1931,theWavelengths);

        %% Load in a standard daylight as our reference spectrum

        theIlluminantData = load('spd_D65');
        theIlluminant = SplineSpd(theIlluminantData.S_D65,theIlluminantData.spd_D65,theWavelengths);
        theIlluminant = theIlluminant/(theXYZCMFs(2,:)*theIlluminant);

        %% Compute XYZ coordinates of the light relfected to the eye
        % First compute light reflected to the eye from the surface,
        % then XYZ.
        theLightToEye = theIlluminant.*theReflectance;
        XYZSur = theXYZCMFs*theLightToEye;
        trueXYZ(:,(ii-1)*length(reflectanceNumbers)+jj) = XYZSur;
    end
end


