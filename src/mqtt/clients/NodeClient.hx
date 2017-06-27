package mqtt.clients;

import js.node.events.EventEmitter;
import js.node.Buffer;
import mqtt.*;
import mqtt.Client;
import tink.Chunk;

using tink.CoreApi;

class NodeClient implements Client {
	
	public var message(default, null):Signal<Pair<String, Chunk>>;
	var messageTrigger:SignalTrigger<Pair<String, Chunk>>;
	var client:NativeClient;
	
	function new(client) {
		this.client = client;
		message = messageTrigger = Signal.trigger();
		client.on('message', function(topic:String, message:Buffer) messageTrigger.trigger(new Pair(topic, (message.hxToBytes():Chunk))));
	}
	
	public static function connect(url:String):Promise<Client> {
		return Future.async(function(cb) {
			var client = NativeMqtt.connect(url);
			
			var onError, onConnect;
			
			onError = function(err) {
				cb(Failure(toError(err)));
				client.removeListener('connect', onConnect);
			}
			
			onConnect = function() {
				cb(Success(new NodeClient(client).asClient()));
				client.removeListener('error', onError);
			}
			
			client.once('error', onError);
			client.once('connect', onConnect);
		});
	}
	
	public function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS> {
		return Future.async(function(cb) {
			client.subscribe(topic, options, function(err, granted) cb(err == null ? Success(granted.qos) : Failure(toError(err))));
		});
	}
	
	public function unsubscribe(topic:String):Promise<Noise> {
		return Future.async(function(cb) {
			client.unsubscribe(topic, cb.bind(Success(Noise)));
		});
	}
	
	public function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise> {
		return Future.async(function(cb) {
			client.publish(
				topic,
				Buffer.hxFromBytes(message.toBytes()),
				options == null ? null : {
					qos: options.qos,
					retain: options.retain,
					dup: options.duplicate,
				}, 
				function(err) cb(err == null ? Success(Noise) : Failure(toError(err)))
			);
		});
	}
	
	public function close(?force:Bool):Future<Noise> {
		return Future.async(function(cb) {
			client.end(force, cb.bind(Noise));
		});
	}
	
	inline function asClient():Client
		return this;
	
	static function toError(e:js.Error)
		return Error.withData(500, e.message, e);
}


@:jsRequire('mqtt')
private extern class NativeMqtt {
	public static function connect(url:String):NativeClient;
}

private extern class NativeClient extends EventEmitter<NativeClient> {
	function publish(topic:String, message:Buffer, ?options:{}, ?callback:js.Error->Void):Void;
	function subscribe(topic:String, ?options:{}, ?callback:js.Error->{qos:QoS}->Void):Void;
	function unsubscribe(topic:String, ?callback:Void->Void):Void;
	function end(force:Bool, ?callback:Void->Void):Void;
}