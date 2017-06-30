function tokens = stringTokenizer(string, delimiter)
%
% STRINGTOKENIZER This funciton returns a cell with the strings that are
% between the specified delimiter
% 

idx = 1;
remain = string;
while ~strcmp(remain, '')
    [tokens{idx}, remain] = strtok(remain, delimiter);
    idx = idx + 1;
end

end

