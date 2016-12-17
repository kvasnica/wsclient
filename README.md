# WSClient - websocket client for Matlab

The `WSClient` class adds a convenient UI to the [matwebsocks](https://github.com/kvasnica/matwebsocks) package. Its primary purpose is to create a websocket connection to the server, send messages over the websockets, and listen for incoming messages.

## Installation

The `wsclient` package can be installed by [tbxmanager](http://www.tbxmanager.com):

```
tbxmanager install wsclient matwebsocks eventcollector
```

where [matwebsocks](https://github.com/kvasnica/matwebsocks) is a required dependency and [eventcollector](https://github.com/kvasnica/eventcollector) is an optional extension.

Make sure to run `matws_install` after installing the `matwebsocks` package to put all necessary Java libraries to the static Matlab Java class path.

## Updating

To update the wsclient package (and other installed packages as well) to the latest version, use

```
tbxmanager update
```

## Usage

`client = WSClient(URL)` creates the object `client ` which represents a websocket pointing to `URL`.
When the client is created, the connection is not yet open. To establish the connection, 
call `client.connect()`. To close the connection, use `client.close()`.
 
Actual status of the connection can be retrieved by `[S, N] = client.getStatus()` where `S` is the status string and `N` is the status number (0=connecting, also provided when the client was never connected,
  1=open, 2=closing, 3=closed).
 
`client.send(DATA)` sends data to the websocket. Unless specified otherwise, `DATA` must be a string. The `send()` method can be configured to automatically convert any Matlab objects to strings by specifying a message encoder: 

```
client = WSClient(URL, 'Encoder', ENCODERCB)
```
where `ENCODERCB` is a function handle. The encoding function must take
  the data to be encoded as the input and return a string. As an
  example, to configure the client to send numeric data, use
  
```
client = WSClient(URL, 'Encoder', @(data) num2str(data))
```

The client can also send raw string messages by `client.sendRaw(msg)`, bypassing the encoder function.
 
When a new message arrives from the websocket, the client stores the raw string message in 
`client.Raw` and the decoded message in `client.Message`:
 
```
decoded_message = client.Message
raw_message = client.Raw
```
 
The decoder is specified by

```
client = WSClient(URL, 'Decoder', DECODERCB)
```
where `DECODERCB` is a function handle of the decoding function that
takes the raw message as an input and returns the decoded object. As
an example, to configure the client to automatically convert string messages
to numbers, use

```
client = WSClient(URL, 'Decoder', @(string) str2double(string))
``` 

If the encoder or the decoder are not specified, the decoded/encoded
message is equal to the raw message.
 
The local timestamp of the last received message is available in
`client.LastReceiveTS`.
 
The `WSClient` class defines several events which you can subscribe to by `client.addlistener(EVENTID, EVENTCB)` where `EVENTID` is a string identificator of the message and `EVENTCB` is
a callback function. The callback must take two inputs:

1. the source of the event `SOURCEOBJ`;
2. an instance of the `WSEvent` class `EVENTDATA` which contains event-specific data in `EVENTDATA.Message`. 

Available events:

* `'MessageReceived'` is triggered when a new decoded message is available. `EVENTDATA.Message` contains the decoded message.
* `'MessageSent'` is triggered when a new encoded message is sent by the client. `EVENTDATA.Message` contains the encoded message.
* `'SocketConnecting'` is triggered before the connection to the websocket is opened. `EVENTDATA.Message` contains the socket URL.
* `'SocketOpened'` is triggered when the connection to the websocket is opened. `EVENTDATA.Message` contains the socket URL.
* `'SocketClosing'` is triggered before the connection to the websocket is closed. `EVENTDATA.Message` contains the socket URL.
* `'SocketClosed'` is triggered when the connection to the websocket is closed. `EVENTDATA.Message` contains the socket URL.
 
As an example, to print the socket URL when the connection is established and closed, use

```
client.addlistener('SocketOpened', @(s,e) disp(['Opened: ',e.Message]));
client.addlistener('SocketClosed', @(s,e) disp(['Closed: ',e.Message]));
```
 
To print the received decoded message, subscribe to the `MessageReceived` event:

```
client.addlistener('MessageReceived', @(s,e) disp(e.Message))
``` 

## Basic demo

```
% create the websocket client
client = WSClient('ws://kirp.chtf.stuba.sk:8025/test/echo')

% connect the client
client.connect()

% send a string message
client.send('message to the echo server')

% read the server's reply (same as the sent event since we are using an "echo" server)
pause(0.1)
reply = client.Message 

% close the client
client.close()
```

## Advanced demos

* [String echo example using events](https://github.com/kvasnica/wsclient/blob/master/src/ws_demo_echo.m)
* [Echo with JSON decoder/encoder](https://github.com/kvasnica/wsclient/blob/master/src/ws_demo_json.m)
* [Simple websocket-based calculator](https://github.com/kvasnica/wsclient/blob/master/src/ws_demo_multiply.m)
* [How to subscribe to events](https://github.com/kvasnica/wsclient/blob/master/src/ws_demo_status.m)
* [Implementation of a custom protocol](https://github.com/kvasnica/wsclient/blob/master/src/ws_demo_wrc.m)
* [In-the-background collection of events](https://github.com/kvasnica/wsclient/blob/master/src/ws_demo_collector.m)
