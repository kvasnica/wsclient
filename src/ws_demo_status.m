% This demo shows how to observe the socket's internal state transitions
% (connecting, opened, closed)

client = WSClient('ws://kirp.chtf.stuba.sk:8025/test/echo');

opened_cb = @(~, e) fprintf('Socket was opened: %s\n', e.Message);
closed_cb = @(~, e) fprintf('Socket was closed: %s\n', e.Message);
connecting_cb = @(~, e) fprintf('Socket is connecting to %s\n', e.Message);
closing_cb = @(~, e) fprintf('Socket is closing: %s\n', e.Message);
received_cb = @(~, e) fprintf('New message arrived: %s\n', e.Message);
sent_cb = @(~, e) fprintf('New message was sent: %s\n', e.Message);

client.addlistener('SocketOpened', opened_cb);
client.addlistener('SocketClosed', closed_cb);
client.addlistener('SocketConnecting', connecting_cb);
client.addlistener('SocketClosing', closing_cb);
client.addlistener('MessageReceived', received_cb);
client.addlistener('MessageSent', sent_cb);

client.connect();
client.send('Hello');
client.close();
