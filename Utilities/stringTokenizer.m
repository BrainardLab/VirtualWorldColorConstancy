function tokens = stringTokenizer(string, delimiter)
%STRINGTOKENIZER Summary of this function goes here
%   Detailed explanation goes here

idx = 1;
remain = string;
while ~strcmp(remain, '')
    [tokens{idx}, remain] = strtok(remain, delimiter);
    idx = idx + 1;
end

end

