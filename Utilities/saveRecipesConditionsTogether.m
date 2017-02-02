function saveRecipesConditionsTogether(p)

projectName = 'VirtualWorldColorConstancy';
filename = fullfile(getpref(projectName, 'baseFolder'),'Cases','Cases.txt');

fieldNames = {
    'outputName'
    'baseSceneSet'
    'shapeSet'
    'illuminantSpectraRandom'
    'otherObjectReflectanceRandom'    
    'lightPositionFixed'
    'lightScaleFixed'
    'targetPositionFixed'
    'targetScaleFixed'
    'luminanceLevels'
    'reflectanceNumbers'};

if ~exist(filename)
    fid = fopen(filename,'wt');
    for numFields = 1 : numel(fieldNames)
        switch fieldNames{numFields}
            case {'illuminantSpectraRandom'}
                fprintf(fid, '%20s\t', 'Illuminant Spectra');
            case {'otherObjectReflectanceRandom'}
                fprintf(fid, '%20s\t', 'Background Spectra');
            otherwise
                fprintf(fid, '%20s\t', fieldNames{numFields});
        end
        
    end
    fprintf(fid, '\n');    
else
    fid = fopen(filename,'at');
end

for numFields = 1 : numel(fieldNames)
    subFields = p.Results.(fieldNames{numFields});
    switch fieldNames{numFields}
        case {'outputName'}
            fprintf(fid, '%20s\t', subFields);
        case {'baseSceneSet'}
            if (numel(subFields) == 1)
                fprintf(fid, '%20s\t', subFields{:});
            else
                fprintf(fid, '%20s\t', [num2str(numel(subFields)),' Scenes']);
            end
        case {'shapeSet'}
            if (numel(subFields) == 1)
                fprintf(fid, '%20s\t', subFields{:});
            else
                fprintf(fid, '%20s\t', [num2str(numel(subFields)),' Objects']);
            end
        case {'luminanceLevels', 'reflectanceNumbers'}
            subFields = num2str(subFields);
            fprintf(fid, '%20s', subFields);
            fprintf(fid, '\t');
        case {'illuminantSpectraRandom', 'otherObjectReflectanceRandom'}
            if (subFields==0)
                fprintf(fid, '%20s\t', 'Fixed');
            else
                fprintf(fid, '%20s\t', 'Random');
            end
        case {'lightPositionFixed', ...
                'lightScaleFixed', 'targetPositionFixed', 'targetScaleFixed'}
            if (subFields==0)
                fprintf(fid, '%20s\t', 'Random');
            else
                fprintf(fid, '%20s\t', 'Fixed');
            end
    end
end
fprintf(fid, '\n');
fclose(fid);