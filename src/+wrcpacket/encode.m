function out = encode(data)
% WRC packet encoder
%
% P = wrcpacket.encode(DATA) converts the structure DATA into a WRC packet
% by adding a current timestamp.

% dead-simple, dead-limited json encoder
jdata = '';
f = fieldnames(data);
for i = 1:length(f)
    v = data.(f{i});
    if ischar(v)
        v = ['"' v '"'];
    elseif isa(v, 'double')
        v = num2str(v, 16);
    else
        error('Unsupported type "%s".', class(v));
    end
    s = sprintf('"%s":%s', f{i}, v);
    jdata = [jdata, s];
    if i < length(f)
        jdata = [jdata, ','];
    end
end

% convert current timestamp to Zulu time string
offset = java.util.Date().getTimezoneOffset;
time = [datestr(now+offset/1440, 'yyyy-mm-ddTHH:MM:SS.FFF'), 'Z'];

% WRC packets have a timestamp "t" and data structure "d"
out = sprintf('{"t":"%s","d":{%s}}', time, jdata);

end
