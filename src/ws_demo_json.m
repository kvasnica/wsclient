% Simple JSON echo example.
%
% We connecto to a special echo server which simply transmits the message
% back to the sender. The websocket is configured such that it decodes
% incoming JSON strings into Matlab structures (or arrays therefore).
% When sending data, the client uses a JSON encoder which converts Matlab
% data structures into JSON strings before sending them.

% initialize the JSON package
tbxmanager require matlabjson

% create the client with JSON decoding/encoding:
%   decoding = translation of JSON strings to Matlab's data structures
%              via data=json.load(string)
%   decoding = translation of Matlab's data structures to JSON strings
%              via string=json.dump(data)
client = WSClient('ws://echo.websocket.org/', ...
    'decoder', @(m) json.load(m), ...
    'encoder', @(m) json.dump(m) );

% set the callback function which gets triggered when a new message arrives
callback = @(~, event) disp(event.Message);
client.addlistener('MessageReceived', callback);

% connect the client
client.connect();

% send structure
fprintf('Sending first structure...\n');
client.send(struct('time', datestr(now, 'HH:MM:SS.FFF'), 'value', 1));

fprintf('Sending second structure...\n');
client.send(struct('time', datestr(now, 'HH:MM:SS.FFF'), 'value', 2));

% you should see two structures being printed in the command window

% close the client
pause(0.1)
client.close();
