package mqtt.clients;

import mqtt.*;
import mqtt.Client;
import haxe.Constraints;
import tink.Chunk;
import haxe.io.Bytes;
import tink.state.*;

using tink.CoreApi;

/**
 *  A MQTT client that works on React Native
 *  Requires the npm package 'react-native-paho-mqtt'
 */
class ReactNativePahoClient extends BaseClient {
	
	var client:NativeClient;
	var config:{};
	
	public function new(config) {
		super();
		this.config = config;
	}
	
	override function connect():Promise<Noise> {
		return Future.async(function(cb) {
			client = new NativeClient(config);
			
			client.connect(config)	
				.then(function(_) {
					isConnectedState.set(true);
					client.on('messageReceived', function(message:{destinationName:String, payloadBytes:js.html.Uint8Array}) {
						var chunk:Chunk = Bytes.ofData(message.payloadBytes.buffer.slice(message.payloadBytes.byteOffset));
						messageTrigger.trigger(new Pair(message.destinationName, chunk));
					});
					
					client.on('connectionLost', function(e) {
						js.Browser.console.log('lost', e);
					});
					client.on('connectionLost', isConnectedState.set.bind(false));
					client.on('error', function(e) errorTrigger.trigger(Error.ofJsError(e)));
					cb(Success(Noise));
				})
				.catchError(function(e) cb(Failure(Error.ofJsError(e))));
		}, false);
	}
	
	override function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS> {
		return Future.async(function(cb) {
			client.subscribe(topic, options)
				.then(function(o) cb(Success(o.grantedQos)))
				.catchError(function(e) cb(Failure(Error.ofJsError(e))));
		}, false);
	}
	
	override function unsubscribe(topic:String):Promise<Noise> {
		return Future.async(function(cb) {
			client.unsubscribe(topic)
				.then(function(_) cb(Success(Noise)))
				.catchError(function(e) cb(Failure(Error.ofJsError(e))));
		}, false);
	}
	
	override function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise> {
		return Future.async(function(cb) {
			var msg = new NativeMessage(new js.html.Int8Array(message.toBytes().getData()));
			msg.destinationName = topic;
			client.send(msg);
			cb(Success(Noise));
		}, false);
	}
	
	override function close(?force:Bool):Future<Noise> {
		return Future.async(function(cb) {
			client.disconnect();
		}, false);
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