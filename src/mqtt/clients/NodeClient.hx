package mqtt.clients;

import js.node.events.EventEmitter;
import js.node.Buffer;
import mqtt.*;
import mqtt.Client;
import tink.state.*;
import tink.Chunk;

using tink.CoreApi;

/**
 *  A MQTT client that works on Node.js
 *  Requires the npm package 'mqtt'
 */
class NodeClient extends BaseClient {
	
	var native:NativeClient;
	
	override function connect():Promise<Noise> {
		return Future.async(function(cb) {
			getConfig().handle(function(o) switch o {
				case Success(config):
					native = NativeMqtt.connect(config.uri, {
						clientId: config.clientId,
						protocolVersion: config.version,
						connectTimeout: config.connectTimeoutMs,
						username: config.username,
						password: config.password,
					});
					
					var onError, onConnect;
					
					onError = function(err) {
						cb(Failure(toError(err)));
						native.removeListener('connect', onConnect);
					}
					
					onConnect = function() {
						cb(Success(Noise));
						isConnectedState.set(true);
						native.removeListener('error', onError);
					}
					
					native.once('error', onError);
					native.once('connect', onConnect);
					
					native.on('message', function(topic:String, message:Buffer) messageTrigger.trigger(new Pair(topic, (message.hxToBytes():Chunk))));
					native.on('close', isConnectedState.set.bind(false));
					native.on('error', function(e) errorTrigger.trigger(toError(e)));
					
				case Failure(e):
			});
		});
	}
	
	override function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS> {
		return Future.async(function(cb) {
			native.subscribe(topic, options, function(err, granted) cb(err == null ? Success(granted.qos) : Failure(toError(err))));
		});
	}
	
	override function unsubscribe(topic:String):Promise<Noise> {
		return Future.async(function(cb) {
			native.unsubscribe(topic, cb.bind(Success(Noise)));
		});
	}
	
	override function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise> {
		return Future.async(function(cb) {
			native.publish(
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
	
	override function close(?force:Bool):Future<Noise> {
		return Future.async(function(cb) {
			native.end(force, cb.bind(Noise));
		});
	}
	
	static function toError(e:js.Error)
		return Error.withData(500, e.message, e);
}


@:jsRequire('mqtt')
private extern class NativeMqtt {
	public static function connect(url:String, ?options:{}):NativeClient;
}

private extern class NativeClient extends EventEmitter<NativeClient> {
	function publish(topic:String, message:Buffer, ?options:{}, ?callback:js.Error->Void):Void;
	function subscribe(topic:String, ?options:{}, ?callback:js.Error->{qos:QoS}->Void):Void;
	function unsubscribe(topic:String, ?callback:Void->Void):Void;
	function end(force:Bool, ?callback:Void->Void):Void;
}