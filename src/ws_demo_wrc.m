% This demo shows how to use a custom protocol over websockets.
%
% In particular, we use the WRC protocol which encodes numeric data as
% structures with a timestamp added to the data. Upon sending, the
% wrcpacket.encode() function takes the input data as a matlab structure,
% adds a timestamp and converts the data structure to a JSON string. Upon
% receive, the wrcpacket.decode() function is called whose purpose is to
% decode the data by first translating a JSON string to a Matlab structure,
% followed by stripping away the timestamp.

error('This demo requires infrastructure that is not working at this time.');

% ask the user for the topic ID
wrc_link = 'http://swsb.uiam.sk/html/sliders.html';
fprintf('Visit %s and enter the topic ID below\n', wrc_link);
topic = input('Topic ID: ', 's');

% full websocket URL to connect to
socket_url = ['ws://swsb.uiam.sk/t/' topic];

% websocket client with custom decoder/encoder
%
% note that although we call the object "receiver", it in fact represents a
% bi-directinal data channel which can also send data.
receiver = WSClient(socket_url, ...
    'Decoder', @(x) wrcpacket.decode(x), ...
    'Encoder', @(x) wrcpacket.encode(x) );
receiver.connect();

% display the received decoded message when it arrives:
callback = @(sender, event) disp(event.Message);
receiver.addlistener('MessageReceived', callback);

fprintf('\nNow play with the sliders/buttons and observe the received data\n');
fprintf('(press any key to abort)\n');
pause

receiver.close();
