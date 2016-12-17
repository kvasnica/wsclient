% Simple text message echo example.
%
% We connecto to a special echo server which simply transmits the message
% back to the sender.

% create the websocket client
client = WSClient('ws://echo.websocket.org/');

% set the callback function which gets triggered when a new message arrives
callback = @(~, event) fprintf('Server response: %s\n', event.Message);
client.addlistener('MessageReceived', callback);

% connect the client
client.connect();

% send a message
fprintf('Sending "Hello"...\n');
client.send('Hello');

fprintf('Sending "Hey"...\n');
client.send('Hey');

% you should see two server responses being printed

% close the client
pause(1)
client.close();
