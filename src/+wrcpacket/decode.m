function data = decode(message)
% WRC packet decoder
%
% WRC packets are JSON dictionaries:
%   {"t":timestamp,"d":data}
%
% This decode first converts the JSON string to a Matlab structure and then
% extracts just the "d" field.

% dead-simple, dead-limited json parser

pattern = '\{"t":"(.*)","d":\{(.*)\}\}';
r = regexp(message, pattern, 'tokens');
rest = ['{' r{1}{2} '}'];
pattern = '"([\w_])+":(-?\d+\.?\d*)[,"\}]?';
r = regexp(rest, pattern, 'tokens');
for i = 1:length(r)
    data.(r{i}{1}) = str2double(r{i}{2});
end

end
