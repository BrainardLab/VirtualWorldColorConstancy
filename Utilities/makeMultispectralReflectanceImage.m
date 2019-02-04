function reflectanceImage = makeMultispectralReflectanceImage(pathToRecipeFolder, factoids)
%reflectanceImage = makeMultispectralReflectanceImage(pathToRecipeFolder)
%
% This function returns the multispectral reflectance image which gives the
% ground truth reflectance values at each pixel of the image. 
%
% Input: 
%   pathToRecipeFolder: Path to recipe folder where the files are stored.
%   factoid : factoid struct
% 
% Output:
%   reflectanceImage: multispectral reflectance image
%
% Feb 04 2019: Vijay Singh wrote this

%%
% Find out the object shape indices in the image
objectIndices = unique(factoids.shapeIndex.data(:,:,1)); % mitsuba counts from 0 rather than 1.

% Read the xml file to find out the reflectances assigned to each shape
pathToxmlFile = fullfile(pathToRecipeFolder, 'scenes', 'Mitsuba', 'normal-factoids.xml');
factoidStruct = xml2struct(pathToxmlFile);
shapeReflectances = factoidStruct.scene.bsdf;

% Allocate space for multispectral image
pathToNormalStruct = fullfile(pathToRecipeFolder, 'renderings', 'Mitsuba', 'normal.mat');
normalStruct = load(pathToNormalStruct);
S = normalStruct.S;
reflectanceImage = zeros(size(factoids.shapeIndex.data,1), size(factoids.shapeIndex.data,1), S(3));

% For each object read the corresponding reflectance files and make
% the multispectral reflectnace image
for ii = 1:length(objectIndices)
    
    % Find pixels with this object index
    [row, col] = find(factoids.shapeIndex.data(:,:,1) == objectIndices(ii));
    
    % Read the reflectance file for this shape index
    pathToReflectanceFile = fullfile(pathToRecipeFolder, shapeReflectances{ii}.spectrum.Attributes.filename);
    [wavelength, magnitude] = rtbReadSpectrum(pathToReflectanceFile);
    magnitudeResampled = SplineSrf(WlsToS(wavelength),magnitude,S);

    for jj = 1:length(row)
        reflectanceImage(row(jj), col(jj),:) = magnitudeResampled;
    end
end

end