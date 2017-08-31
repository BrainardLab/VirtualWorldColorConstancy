function multispectralImage = parload(fname)
%multispectralImage = parload(fname)
%
% Usage: 
%   radiance = parload(pathToRadianceFile);
%
% Description:
%   This function loads the data in the .mat file inside a parfor loop.
%
% Input:
%   fname = filename
%
% Output:
%   multispectralImage = multispectral image stored in the .mat file
% 
radiance = load(fname);
multispectralImage = radiance.multispectralImage;
end
