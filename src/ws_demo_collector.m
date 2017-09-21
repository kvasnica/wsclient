% This demo shows how to use the EventCollector object to record, in the
% background, all events triggered by a particular object.
%
% In this case the collector archives all incoming messages for a given
% webscket.

% this demo requires the "eventcollector" package
tbxmanager require eventcollector

ws = 'ws://swsb.uiam.sk/t/demo/collector';

% create a sender which emits numeric inputs
numeric_sender = WSClient(ws, 'Encoder', @(x) num2str(x));
numeric_sender.connect();

% receiver decodes incoming string messages to numbers
numeric_receiver = WSClient(ws, 'Decoder', @(x) str2double(x));
numeric_receiver.connect();

% create a collector for the receiver
collector = numeric_receiver.getCollector();

% send some data over the sender
for i = 1:10
    numeric_sender.send(i);
end

% the data was recorded in the recorder's collector:
pause(0.3);
received_data = collector.all()

% see "help EventCollector" for information how to access the collected
% events

% cleanup
numeric_sender.close();
numeric_receiver.close();
