package mqtt.clients;

import mqtt.*;
import mqtt.Client;
import haxe.Constraints;
import tink.Chunk;
import haxe.io.Bytes;

using tink.CoreApi;

/**
 *  A MQTT client that works on React Native
 *  Requires the npm package 'react-native-paho-mqtt'
 */
class ReactNativePahoClient implements Client {
	
	public var message(default, null):Signal<Pair<String, Chunk>>;
	var messageTrigger:SignalTrigger<Pair<String, Chunk>>;
	var client:NativeClient;
	
	function new(client) {
		this.client = client;
		message = messageTrigger = Signal.trigger();
		client.on('messageReceived', function(message:{destinationName:String, payloadBytes:js.html.Uint8Array}) {
			var chunk:Chunk = Bytes.ofData(message.payloadBytes.buffer.slice(message.payloadBytes.byteOffset));
			messageTrigger.trigger(new Pair(message.destinationName, chunk));
		});
	}
	
	public static function connect(config:{}):Promise<Client> {
		return Future.async(function(cb) {
			var client = new NativeClient(config);
			
			client.connect(config)	
				.then(function(_) cb(Success(new ReactNativePahoClient(client).asClient())))
				.catchError(function(e) cb(Failure(toError(e))));
		});
	}
	
	public function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS> {
		return Future.async(function(cb) {
			client.subscribe(topic, options)
				.then(function(o) cb(Success(o.grantedQos)))
				.catchError(function(e) cb(Failure(toError(e))));
		});
	}
	
	public function unsubscribe(topic:String):Promise<Noise> {
		return Future.async(function(cb) {
			client.unsubscribe(topic)
				.then(function(_) cb(Success(Noise)))
				.catchError(function(e) cb(Failure(toError(e))));
		});
	}
	
	public function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise> {
		return Future.async(function(cb) {
			var msg = new NativeMessage(new js.html.Int8Array(message.toBytes().getData()));
			msg.destinationName = topic;
			client.send(msg);
			cb(Success(Noise));
		});
	}
	
	public function close(?force:Bool):Future<Noise> {
		return Future.async(function(cb) {
			client.disconnect();
			cb(Noise);
		});
	}
	
	inline function asClient():Client
		return this;
	
	static function toError(e:js.Error) {
		untyped console.log(e);
		return Error.withData(500, e.message, e);
	}
}


@:jsRequire('react-native-paho-mqtt', 'Client')
private extern class NativeClient {
	function new(options:{});
	function on(event:String, f:Function):Void;
	function connect(options:{}):js.Promise<Dynamic>;
	function subscribe(topic:String, ?options:{}):js.Promise<{grantedQos:QoS}>;
	function unsubscribe(topic:String, ?options:{}):js.Promise<Dynamic>;
	function send(message:NativeMessage):Void;
	function disconnect():Void;
}
@:jsRequire('react-native-paho-mqtt', 'Message')
private extern class NativeMessage {
	var destinationName:String;
	function new(message:js.html.Int8Array);
}