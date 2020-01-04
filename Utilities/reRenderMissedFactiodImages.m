function reRenderMissedFactiodImages(outputName)
%reRenderMissedFactiodImages
%
% This function re renders the factiod image struct that were skipped in 
% the first loop. The cause of the skipping is unclear.
%
% Input: 
%   outputName: output name of the folder
% 
% Output:
%   None
%
% Jan 04 2020: Vijay Singh wrote this

pathToErrorFile = fullfile(getpref('VirtualWorldColorConstancy','baseFolder'),outputName, 'ConeResponse','Errors');

if exist(pathToErrorFile,'dir')
    filePattern = fullfile(pathToErrorFile, '*.mat');    
    filenames = dir(filePattern);
    for ii = 1:length(filenames)
        nameOfThisRecipe = filenames(ii).name;
        
        while ~exist(fullfile(getpref('VirtualWorldColorConstancy','baseFolder'),outputName, 'Working', nameOfThisRecipe(1:end-4),'renderings','Mitsuba','normal-factoids.mat'),'file')
            display(['rendering image ',num2str(ii), ' out of ',num2str(length(filenames))]);
            luminanceLevels = str2num(nameOfThisRecipe(13:16))*0.0001;
            reflectanceNumbers = str2num(nameOfThisRecipe(30:32));
            MakeFactoidImagesByCombination('outputName',outputName,'luminanceLevels', luminanceLevels, 'reflectanceNumbers', reflectanceNumbers);
        end
    end
end