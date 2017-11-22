package mqtt.clients;

import mqtt.*;
import mqtt.Client;
import tink.state.*;
import tink.Chunk;
import haxe.Constraints;
import haxe.io.Bytes;

using tink.CoreApi;

/**
 *  A MQTT client for JS
 *  For nodejs: Requires the npm package 'mqtt'
 *  For browser: `<script src="https://unpkg.com/mqtt/dist/mqtt.min.js"></script>`
 */
class JsClient extends BaseClient {
	
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
						reconnectPeriod: 0, // don't reconnect
					});
					
					var onClose, onError, onConnect;
					
					onClose = function(err) {
						cb(Failure(toError(err)));
						native.removeListener('error', onError);
						native.removeListener('connect', onConnect);
					}
					
					onError = function(err) {
						cb(Failure(toError(err)));
						native.removeListener('close', onClose);
						native.removeListener('connect', onConnect);
					}
					
					onConnect = function() {
						cb(Success(Noise));
						isConnectedState.set(true);
						native.removeListener('error', onError);
						native.removeListener('close', onClose);
						if(config.topics != null) for(topic in config.topics) subscribe(topic);
					}
					
					native.once('error', onError);
					native.once('close', onClose);
					native.once('connect', onConnect);
					
					native.on('message', function(topic:String, message:Message) {
						var chunk:Chunk = 
							#if nodejs
								message.hxToBytes()
							#else
								Bytes.ofData(message.buffer.slice(message.byteOffset))
							#end ;
						messageTrigger.trigger(new Pair(topic, chunk));
					});
					native.on('close', isConnectedState.set.bind(false));
					native.on('error', function(e) errorTrigger.trigger(toError(e)));
					
				case Failure(e):
			});
		});
	}
	
	override function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS> {
		return Future.async(function(cb) {
			native.subscribe(topic, options, function(err, granted) cb(err == null ? Success(granted.qos) : Failure(toError(err))));
		}, false);
	}
	
	override function unsubscribe(topic:String):Promise<Noise> {
		return Future.async(function(cb) {
			native.unsubscribe(topic, cb.bind(Success(Noise)));
		}, false);
	}
	
	override function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise> {
		return Future.async(function(cb) {
			native.publish(
				topic,
				#if nodejs
					Message.hxFromBytes(message.toBytes()),
				#else
					new Message(message.toBytes().getData()),
				#end
				options == null ? null : {
					qos: options.qos,
					retain: options.retain,
					dup: options.duplicate,
				}, 
				function(err) cb(err == null ? Success(Noise) : Failure(toError(err)))
			);
		}, false);
	}
	
	override function close(?force:Bool):Future<Noise> {
		return Future.async(function(cb) {
			native.end(force, cb.bind(Noise));
		}, false);
	}
	
	static function toError(e:js.Error)
		return Error.withData(500, e.message, e);
}


#if nodejs
@:jsRequire('mqtt')
#else
@:native('mqtt')
#end
private extern class NativeMqtt {
	public static function connect(url:String, ?options:{}):NativeClient;
}

private extern class NativeClient {
	function on(event:String, f:Function):Void;
	function once(event:String, f:Function):Void;
	function removeListener(event:String, f:Function):Void;
	function publish(topic:String, message:Message, ?options:{}, ?callback:js.Error->Void):Void;
	function subscribe(topic:String, ?options:{}, ?callback:js.Error->{qos:QoS}->Void):Void;
	function unsubscribe(topic:String, ?callback:Void->Void):Void;
	function end(force:Bool, ?callback:Void->Void):Void;
}

typedef Message = #if nodejs js.node.Buffer #else js.html.Uint8Array #end;