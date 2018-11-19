package mqtt.servers;

import mqtt.Server;
import tink.Chunk;

using tink.CoreApi;

class NodeServer implements Server {
	public var clientConnected(default, null):Signal<ConnectedClient>;
	public var messageReceived(default, null):Signal<Message>;
	
	var server:MoscaServer;
	
	public function new(?opt) {
		server = new MoscaServer(opt);
		
		if(opt != null && (cast opt).http != null)
			server.attachHttpServer((cast opt).http);
		
		messageReceived = Signal.generate(function(trigger) {
			server.on('published', function(message:Dynamic, client) {
				var chunk = Std.is(message.payload, String) ? Chunk.ofString(message.payload) : Chunk.ofBuffer(message.payload);
				trigger(new Pair(message.topic, chunk));
			});
		});
		
		clientConnected = Signal.generate(function(trigger) {
			server.on('clientConnected', function(client) trigger((new NodeConnectedClient(client):ConnectedClient)));
		});
	}
	
	public function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise> {
		server.publish({
			topic: topic,
			payload: message.toBuffer(),
			qos: options == null ? null : options.qos,
			retain: options == null ? null : options.retain,
		});
		return Noise;
	}
	
	public function close():Future<Noise> {
		return Future.async(function(cb) server.close(cb.bind(Noise)));
	}
}

class NodeConnectedClient implements ConnectedClient {
	
	public var closed(default, null):Future<Noise>;
	
	var closedTrigger:FutureTrigger<Noise>;
	var client:MoscaClient;
	
	public function new(client:MoscaClient) {
		closed = Future.async(function(cb) {
			client.server.on('clientDisconnected', function listener(c) if(c == client) {
				client.server.removeListener('clientDisconnected', listener);
				cb(Noise);
			});
		});
		closed = closedTrigger = Future.trigger();
	}
	
	public function close():Future<Noise> {
		client.close(closedTrigger.trigger.bind(Noise));
		return closed;
	}
}

@:jsRequire('mosca', 'Server')
extern class MoscaServer extends js.node.events.EventEmitter<MoscaServer> {
	function new(?opt:{});
	function close(cb:Void->Void):Void;
	function publish(opt:{}):Void;
	function attachHttpServer(server:js.node.http.Server):Void;
}

extern class MoscaClient extends js.node.events.EventEmitter<MoscaClient> {
	var server:MoscaServer;
	function close(cb:Void->Void):Void;
}