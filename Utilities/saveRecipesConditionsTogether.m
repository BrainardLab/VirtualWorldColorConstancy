function saveRecipesConditionsTogether(p)

% This function saves the recipe conditions specified in the fieldNames
% variable below and saves it to the Cases/Cases.txt file in the
% VirtualWorldColorConstancy folder. 
% If /Cases/Cases.txt does not exits this creates the corresponding file
% and directory and saves the recipe data. Otherwise it appends the
% information to the existing file.
%
% Written by VS 02/02/2017


projectName = 'VirtualWorldColorConstancy';
if ~exist(fullfile(getpref(projectName, 'baseFolder'),'Cases'))
    mkdir(fullfile(getpref(projectName, 'baseFolder'),'Cases'))
end
filename = fullfile(getpref(projectName, 'baseFolder'),'Cases','Cases.txt');

fieldNames = {
    'outputName'
    'baseSceneSet'
    'shapeSet'
    'illuminantSpectraRandom'
    'otherObjectReflectanceRandom'    
    'lightPositionRandom'
    'lightScaleRandom'
    'targetPositionRandom'
    'targetScaleRandom'
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
            case {'lightPositionRandom'}
                fprintf(fid, '%20s\t', 'Light Position');
            case {'lightScaleRandom'}
                fprintf(fid, '%20s\t', 'Light Scale');
            case {'targetPositionRandom'}
                fprintf(fid, '%20s\t', 'Target Position');
            case {'targetScaleRandom'}
                fprintf(fid, '%20s\t', 'Target Scale');
            otherwise
                fprintf(fid, '%20s\t', fieldNames{numFields});
        end                
    end
    fprintf(fid, '%20s\t', 'Date & Time');
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
        case {'lightPositionRandom', ...
                'lightScaleRandom', 'targetPositionRandom', 'targetScaleRandom'}
            if (subFields==0)
                fprintf(fid, '%20s\t', 'Fixed');
            else
                fprintf(fid, '%20s\t', 'Random');
            end
    end
end
fprintf(fid, '%20s\t', datetime);
fprintf(fid, '\n');
fclose(fid);