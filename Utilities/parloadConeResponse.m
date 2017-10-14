function ConeResponse = parloadConeResponse(fname)
%ConeResponse = parloadConeResponse(fname)
%
% Usage: 
%   radiance = parloadConeResponse(pathToConeResponse);
%
% Description:
%   This function loads the data in the .mat file inside a parfor loop.
%
% Input:
%   fname = filename
%
% Output:
%   ConeResponse = ConeResponse recipe struct
% 
ConeResponse = load(fname);
ConeResponse = ConeResponse.recipe;
end
