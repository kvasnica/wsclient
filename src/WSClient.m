classdef WSClient < handle
    % Matlab websocket client
    %
    % Prerequisites:
    % ==============
    %
    % This class interfaces the sk.stuba.fchpt.kirp.MatlabWebSocketClient
    % java class which must be installed via 
    % "tbxmanager install matwebsocks"
    %
    % After installing the "matwebsocks" package, run "matws_install()" to
    % add necessary java packages to the static java class path.
    %
    % Usage:
    % ======
    %
    % client = WSClient(URL) creates the client that represents a websocket
    % pointing to URL.
    %
    % When the client is created, the connection is not yet open. To
    % establish the connection, call client.connect(). To close the
    % connection, use client.close().
    %
    % Actual status of the connection can be retrieved by
    %   [S, N] = client.getStatus()
    % where S is the status string and N is the status number
    % (0=connecting, also provided when the client was never connected,
    % 1=open, 2=closing, 3=closed)
    %
    % client.send(DATA) sends data to the websocket. Unless specified
    % otherwise, DATA must be a string. The client can be configured to
    % automatically convert any Matlab objects to strings by specifying a
    % message encoder: 
    %   client = WSClient(URL, 'Encoder', ENCODERCB)
    % where ENCODERCB is a function handle. The encoding function must take
    % the data to be encoded as the input and return a string. As an
    % example, to configure the client to send numeric data, use
    %   client = WSClient(URL, 'Encoder', @(data) num2str(data))
    %
    % The client can also send raw string messages by CLIENT.sendRaw(msg),
    % bypassing the encoder function.
    %
    % When a new message arrives from the websocket, the client stores the
    % raw string message in client.Raw and the decoded message in
    % client.Message:
    %
    %   decoded_message = client.Message
    %       raw_message = client.Raw
    %
    % The decoder is specified by
    %   client = WSClient(URL, 'Decoder', DECODERCB)
    % where DECODERCB is a function handle of the decoding function that
    % takes the raw string as an input and returns the decoded object. As
    % an example, to configure the client to automatically convert strings
    % into numbers, use
    %   client = WSClient(URL, 'Decoder', @(string) str2double(string))
    %
    % If the encoder or the decoder are not specified, the decoded/encoded
    % message is equal to the raw message.
    %
    % The local timestamp of the last received message is available in
    % CLIENT.LastReceiveTS.
    %
    % The client defines events which you can subscribe to by
    %   client.addlistener(EVENTID, EVENTCB)
    % where EVENTID is a string identificator of the message and EVENTCB is
    % a callback function. The callback must take two inputs:
    %   1) the source of the event SOURCEOBJ
    %   2) an instance of the WSEvent class EVENTDATA which contains
    %      event-specific data in EVENTDATA.Message. 
    % 
    % Available events:
    % * EVENTID='MessageReceived' is triggered when a new decoded message
    %   is available. EVENTDATA.Message contains the decoded message.
    % * EVENTID='MessageSent' is triggered when a new encoded message is
    %   sent by the client. EVENTDATA.Message contains the encoded message.
    % * EVENTID='SocketOpened' is triggered when the connection to the
    %   websocket is opened. EVENTDATA.Message contains the socket URL.
    % * EVENTID='SocketClosed' is triggered when the connection to the
    %   websocket is closed. EVENTDATA.Message contains the socket URL.
    % * EVENTID='SocketConnecting' is triggered before the connection to
    %   the websocket is opened. EVENTDATA.Message contains the socket URL.
    % * EVENTID='SocketClosing' is triggered before the connection to
    %   the websocket is closed. EVENTDATA.Message contains the socket URL.
    %
    % As an example, to print the socket URL when the connection is
    % established and closed, use
    %   client.addlistener('SocketOpened', @(s,e)disp(['Opened: ',e.Message]));
    %   client.addlistener('SocketClosed', @(s,e)disp(['Closed: ',e.Message]));
    %
    % To print the received decoded message, subscribe to the
    % MessageReceived event:
    %   client.addlistener('MessageReceived', @(s,e) disp(e.Message))
    %
    % Demos:
    % ======
    %   ws_demo_echo       string echo example
    %   ws_demo_json_echo  echo with JSON decoder/encoder
    %   ws_demo_multiply   simple websocket-based calculator
    %   ws_demo_status     shows how to subscribe to events
    %   ws_demo_wrc        illustrates how to implement a simple protocol
    %   ws_demo_collector  shows in-the-background collection of events
    
    % Copyright (c) 2014, Michal Kvasnica (michal.kvasnica@stuba.sk)
    %
    % Legal note:
    %   This program is free software; you can redistribute it and/or
    %   modify it under the terms of the GNU General Public
    %   License as published by the Free Software Foundation; either
    %   version 2.1 of the License, or (at your option) any later version.
    %
    %   This program is distributed in the hope that it will be useful,
    %   but WITHOUT ANY WARRANTY; without even the implied warranty of
    %   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    %   General Public License for more details.
    %
    %   You should have received a copy of the GNU General Public
    %   License along with this library; if not, write to the
    %   Free Software Foundation, Inc.,
    %   59 Temple Place, Suite 330,
    %   Boston, MA  02111-1307  USA

    properties(SetAccess=private)
        Server        % websocket URL
        Message       % last decoded message
        Raw           % last raw message
        LastReceiveTS % timestamp of the last received message
    end
    properties(SetAccess=private, Hidden)
        Socket  % sk.stuba.fchpt.kirp.MatlabWebSocketClient object
        Decoder % function handle of a message decoder
        Encoder % function handle of a message encoder
    end
    properties(Constant)
        SOCKET_CONNECTING = 0
        SOCKET_OPEN = 1
        SOCKET_CLOSING = 2
        SOCKET_CLOSED = 3
    end
    events
        MessageReceived  % Notified when a message is received
        MessageSent      % Notified when the client sends a message
        SocketOpened     % Notified when the socket opens
        SocketClosed     % Notified when the socket closes
        SocketConnecting % Notified when connecting to the websocket
        SocketClosing    % Notified when the socket is closing
    end

    methods
        
        function client = WSClient(varargin)
            % Main websocket client constructor

            error(javachk('jvm'));
            p = inputParser;
            p.addRequired('server');
            % no decoding by default:
            p.addParamValue('decoder', [], @(x) isa(x, 'function_handle'));
            % no encoding by default:
            p.addParamValue('encoder', [], @(x) isa(x, 'function_handle'));
            p.parse(varargin{:});
            inputs = p.Results;
            
            client.Server = inputs.server;
            try
                client.Socket = sk.stuba.fchpt.kirp.MatlabWebSocketClient(java.net.URI(client.Server));
            catch err
                % Note to self: the jars must be compiled with
                % "-target 1.6 -source 1.6" options in javac, otherwise
                % Matlab won't load them
                if isequal(err.identifier, 'MATLAB:undefinedVarOrClass')
                    fprintf('\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
                    fprintf('Install necessary Java libraries by "tbxmanager install matwebsocks"\n\n');
                    fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
                end
                rethrow(err)
            end
            client.Decoder = inputs.decoder;
            client.Encoder = inputs.encoder;
        end
        
        function display(client)
            % Overloaded display method for WSClient

            if length(client)>1
                display@handle(client);
                return
            end

            if isequal(inputname(1), 'ans')
                name = 'client';
            else
                name = inputname(1);
            end
            if ~isempty(client.Decoder)
                decoder = char(client.Decoder);
            else
                decoder = 'none';
            end
            if ~isempty(client.Encoder)
                encoder = char(client.Encoder);
            else
                encoder = 'none';
            end
            if isempty(client.LastReceiveTS)
                last_time = 'never';
            else
                last_time = datestr(client.LastReceiveTS, 'dd-mmm-yyyy HH:MM:SS.FFF');
            end
            
            fprintf('\n');
            fprintf('    Websocket URL: %s\n', client.Server);
            fprintf('  Websocket state: %s\n', client.getState());
            fprintf('  Message decoder: %s\n', decoder);
            fprintf('  Message encoder: %s\n', encoder);
            fprintf('     Last receipt: %s\n', last_time);
            if ~isempty(client.LastReceiveTS)
                fprintf('\nUse "%s.Message" to get the decoded message or "%s.Raw" for the raw message.\n', name, name);
            end
            fprintf('\n');
        end
        
        function [str, num] = getState(client)
            % Numeric and string representation of the socket's state
            %
            % [S, N] = client.getState() returns string S and integer N
            % which represent the connection status:
            %
            %   S='CONNECTING', N=0 when the socket is connecting or was
            %                       not yet connected
            %   S='OPEN', N=1       when the socket is open
            %   S='CLOSING', N=2    when the socket is closing
            %   S='CLOSED', N=3     when the socket is closed
            
            assert(numel(client)==1, 'WSCLIENT:TooManyInputs:Single client please');
            s = client.Socket.getReadyState();
            if isa(s, 'double')
                % determine the string representation
                num = s;
                switch s
                    case client.SOCKET_CONNECTING
                        str = 'CONNECTING';
                    case client.SOCKET_OPEN
                        str = 'OPEN';
                    case client.SOCKET_CLOSING
                        str = 'CLOSING';
                    case client.SOCKET_CLOSED
                        str = 'CLOSED';
                    otherwise
                        str = 'UNKNOWN';
                end
            else
                % convert string status flag to a string
                str = char(s);
                switch str
                    case 'CONNECTING'
                        num = client.SOCKET_CONNECTING;
                    case 'OPEN'
                        num = client.SOCKET_OPEN;
                    case 'CLOSING'
                        num = client.SOCKET_CLOSING;
                    case 'CLOSED'
                        num = client.SOCKET_CLOSED;
                    otherwise
                        num = -1;
                end                    
            end
        end
        
        function out = isState(client, desired)
            % Returns true if the socket's state is as desired
            
            assert(numel(client)==1, 'WSCLIENT:TooManyInputs:Single client please');
            [s, n] = client.getState;
            if isa(desired, 'double')
                out = (n==desired);
            else
                out = isequal(s, desired);
            end
        end
        
        function delete(client)
            % WSClient destructor
            %
            % Closes the websocket if it's open.

            for i = 1:numel(client)
                if client(i).isState(client.SOCKET_OPEN)
                    client(i).close();
                end
            end
        end

        function reconnect(client)
            fprintf('try to reconnect');
            client.connect();
        end

        function client = connect(client)
            % Connects the client to the websocket server
            %
            % client.connect()

            % deal with multiple clients
            if numel(client)>1
                for i = 1:numel(client)
                    client(i).connect();
                end
                return
            end

            if client.isState(client.SOCKET_OPEN)
                % already connected
                return
            end

            uri = java.net.URI(client.Server);
            client.Socket = sk.stuba.fchpt.kirp.MatlabWebSocketClient(uri);

            % notify listeners of the SocketConnecting event
            client.notify('SocketConnecting', WSEvent(client.Server));
            client.Socket.connect();
            pause(0.1);
            tries = 0;
            while ~client.isState(client.SOCKET_OPEN)
                tries = tries + 1;
                pause(0.5);
                client.connect();
            end
            % fprintf('Connection established: %s\n', client.Server);

            % Set callback for incoming message
            % NOTE: the socket must be connected before setting the
            %       callback!
            try
                set(client.Socket, 'MessageReceivedCallback', @(h,e) client.message_callback(h,e));
            catch
                % Note that in R2014a and newer we need to wrap the socket as a
                % handle object: http://undocumentedmatlab.com/blog/matlab-callbacks-for-java-events-in-r2014a
                sock = handle(client.Socket, 'CallbackProperties');
                set(sock, 'MessageReceivedCallback', @(h,e) client.message_callback(h,e));
            end

            % notify listeners of the SocketOpened event
            client.notify('SocketOpened', WSEvent(client.Server));
        end
        
        function client = close(client)
            % Disconnects the client
            %
            % client.close()

            % deal with multiple clients
            if numel(client)>1
                for i = 1:numel(client)
                    client(i).close();
                end
                return
            end

            % notify listeners of the SocketClosing event
            client.notify('SocketClosing', WSEvent(client.Server));

            client.Socket.close();
            pause(0.01);
            
            % notify listeners of the SocketClosed event
            client.notify('SocketClosed', WSEvent(client.Server));
        end
        
        function send(client, data)
            % Sends data over a websocket client
            %
            % WSClient.send(DATA) sends DATA over the websocket. If an
            % encoder was specified while creating the client, DATA is
            % first converted to a string via the encoder. If no encoder
            % was specified, DATA must be a string. 
            %
            % Example:
            %   client = WSClient(URL, 'Encoder', @(d) mat2str(d))
            %   client.connect()
            %   client.send(rand(1, 5))

            % reconnect websocket in case of disconnect
            while ~client.isState(client.SOCKET_OPEN)
            client.reconnect();
            end

            % deal with multiple clients
            if numel(client)>1
                for i = 1:numel(client)
                    client(i).send(data);
                end
                return
            end

            % send the encoded message
            if ~isempty(client.Encoder)
                msg = client.Encoder(data);
            else
                msg = data;
            end
            if ~ischar(msg)
                error('WSCLIENT:WrongEncoderOutput', 'The encoder must produce a string.');
            end
            client.sendRaw(msg);
            client.notify('MessageSent', WSEvent(data));
        end
        
        function sendRaw(client, message)
            % Sends a raw string over a websocket client
            %
            % WSClient.sendRaw(MSG) sends the string MSG over the
            % websocket.
            %
            % Example:
            %   client = WSClient(URL, 'Encoder', @(d) mat2str(d))
            %   client.connect()
            %   client.sendRaw('[1, 2, 3]')

            % deal with multiple clients
            if numel(client)>1
                for i = 1:numel(client)
                    client(i).sendRaw(message);
                end
                return
            end

            if ~client.isState(client.SOCKET_OPEN)
                error('WSCLIENT:SocketError', 'The socket is not open.');
            end
            if ~ischar(message)
                error('WSCLIENT:WrongInput', 'The message must be a string.');
            end
            client.Socket.send(message);
        end
        
        function C = getCollector(client)
            % Constructs an EventCollector object for this client
            %
            % See "help EventCollector" for more information.

            assert(numel(client)==1, 'WSCLIENT:TooManyInputs:Single client please');
            C = EventCollector(client, 'MessageReceived', 'EventParser', @(e) e.Message);
        end
        
        function s = char(client)
            % String representation of WSClient objects
            
            assert(numel(client)==1, 'WSCLIENT:TooManyInputs:Single client please');
            s = sprintf('WSClient: %s [%s]', client.Server, lower(client.getState()));
        end
    end
    
    methods (Access = private)
        
        function message_callback(client, ~, e)
            % callback triggered when a new message arrives from the
            % websocket
            
            % convert from java string
            client.Raw = char(e.message);
            
            % decode the message
            if ~isempty(client.Decoder)
                decoded = client.Decoder(client.Raw);
            else
                decoded = client.Raw;
            end
            client.Message = decoded;
            
            % record timestamp
            client.LastReceiveTS = now;
            
            % create the notification event
            event = WSEvent(client.Message);
            
            % notify listeners
            client.notify('MessageReceived', event);
        end
        
    end
    
end
