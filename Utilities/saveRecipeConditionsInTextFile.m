function saveRecipeConditionsInTextFile(p)

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