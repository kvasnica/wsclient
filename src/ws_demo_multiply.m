% This demo creates two websocket clients:
% 1) sender, which sends a number to a websocket
% 2) receiver which receives the number sent by the sender, multiplies it
%    by a factor of two and sends it back to the sender

ws = 'ws://swarm3172.cloudout.co:8025/t/demo/multiply';

% the sender transmits/receives numeric messages
sender = WSClient(ws, 'Encoder', @(x) num2str(x), ...
    'Decoder', @(x) str2double(x));
% callback function displays the received message
sender.addlistener('MessageReceived', @(~, event) disp(event.Message));
sender.connect();

% receiver encodes/decodes messages from/to numbers
receiver = WSClient(ws, 'Encoder', @(x) num2str(x), ...
    'Decoder', @(x) str2double(x));
% the receiver's callback multiplies the incoming number by two and sends
% the result back to over the receiver to all clients which are connected
% to the same topic ("demo/mutliply" in this case)
%
% note that although we call the object "receiver", it in fact represents a
% bi-directinal data channel which can also send data.
callback = @(sender, event) sender.send(2*event.Message); 
receiver.addlistener('MessageReceived', callback);
receiver.connect();

% sender asks the receiver to multiply some numbers
sender.send(100);
sender.send(0.1);
sender.send(-1);

% you should see the results of the multiplications in your command window

% close the sockets
pause(0.5);
sender.close();
receiver.close();
