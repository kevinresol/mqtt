package mqtt.clients;

import haxe.Timer;
import mqtt.Client;
import mqtt.Config;
import tink.Chunk;
import tink.state.*;

using tink.CoreApi;

class KeepAliveClient extends BaseClient {
	
	var subscriptions:Array<Subscription> = [];
	var clientFactory:ConfigGenerator->Client;
	var clientState:State<Client>;
	var client(get, set):Client;
	var link:CallbackLink;
	
	public function new(getConfig, clientFactory) {
		super(getConfig);
		this.clientFactory = clientFactory;
		this.clientState = new State(null);
		this.isConnected = Observable.auto(() -> switch client {
			case null: false;
			case c: c.isConnected.value;
		});
	}
	
	override function connect():Promise<Noise> {
		return switch client {
			case null:
				client = clientFactory(getConfig);
				tryConnect();
			case _:
				new Error('Already connected');
		}
	}
	
	inline function get_client():Client {
		return clientState.value;
	}
	inline function set_client(v:Client) {
		return clientState.set(v);
	}
	
	function tryConnect(delay = 10):Promise<Noise> {
		return client.connect().map(function(o) {
			switch o {
				case Success(_):
					if(link != null) link.dissolve();
					link = client.messageReceived.handle(messageTrigger.trigger)
						& client.errors.handle(errorTrigger.trigger);
					
					for(sub in subscriptions) switch sub {
						case Subscribe(topic, options): client.subscribe(topic, options);
						case Unsubscribe(topic): client.unsubscribe(topic);
					}
					
					client.isConnected.nextTime(function(v) return !v)
						.handle(function(_) {
							client = clientFactory(getConfig);
							tryConnect().eager();
						});
					
				case Failure(e):
					errorTrigger.trigger(e);
					var nextDelay = delay *= 2;
					if(nextDelay > 60000) nextDelay = 60000;
					Timer.delay(tryConnect.bind(nextDelay), delay);
			}
			return o;
		});
	}
	
	override function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS> {
		return Future.async(function(cb) {
			subscriptions.push(Subscribe(topic, options));
			whenConnected(function() client.subscribe(topic, options).handle(cb));
		}, false);
	}
	
	override function unsubscribe(topic:String):Promise<Noise> {
		return Future.async(function(cb) {
			subscriptions.push(Unsubscribe(topic));
			whenConnected(function() client.unsubscribe(topic).handle(cb));
		}, false);
	}
	
	override function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise> {
		return Future.async(function(cb) {
			whenConnected(function() client.publish(topic, message, options).handle(cb));
		}, false);
	}
	
	override function close(?force:Bool):Future<Noise> {
		return Future.async(function(cb) {
			whenConnected(function() {
				client.close(force).handle(cb);
				client = null;
			});
		}, false);
	}
	
	function whenConnected(f:Void->Void) {
		isConnected.nextTime({butNotNow: false}, function(v) return v).handle(f);
	}
}

enum Subscription {
	Subscribe(topic:String, options:SubscribeOptions);
	Unsubscribe(topic:String);
}