function saveRecipeConditionsInTextFile(p)
%saveRecipeConditionsInTextFile(p)
%
% Usage: 
%     saveRecipeConditionsInTextFile(parser)
%
% Description:
%   This function writes all the fields specified in the parser of the
%   RunToyVirtualWorldRecipes function to the file recipeSummary.txt and
%   saves the file in the outputName folder of the outputName specified in
%   RunToyVirtualWorldRecipes.
%
% Input:
%   parser = struct with the recipe information
%
% Written by VS 02/02/2017

projectName = 'VirtualWorldColorConstancy';
filename = fullfile(getpref(projectName, 'baseFolder'),p.Results.outputName,'recipeSummary.txt');
fid = fopen(filename,'wt');

fieldNames = fieldnames(p.Results);

for numFields = 1 : numel(fieldNames)
    fprintf(fid, '%s\t', fieldNames{numFields});
    subFields = p.Results.(fieldNames{numFields});
    if strcmp('outputName',fieldNames{numFields})
        fprintf(fid, '%s\t', subFields);
    else
        
        for numSubfields = 1 : numel(subFields)
            if iscell(subFields(numSubfields))
                fprintf(fid, '%s\t', subFields{numSubfields});
            else
                fprintf(fid, '%s\t', num2str(subFields(numSubfields)));
            end
        end
    end
    fprintf(fid, '\n');
end
fclose(fid);