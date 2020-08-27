package mqtt.clients;

import haxe.Timer;
import mqtt.Client;
import mqtt.Config;
import tink.Chunk;
import tink.state.Observable;

using tink.CoreApi;

class KeepAliveClient implements Client {
	
	public var messageReceived(default, null):Signal<Message>;
	public var errors(default, null):Signal<Error>;
	public var isConnected(default, null):Observable<Bool>;
	
	var errorTrigger:SignalTrigger<Error>;
	var subscriptions:Array<Subscription> = [];
	var clientFactory:ConfigGenerator->Client;
	var client:Client;
	var getConfig:ConfigGenerator;
	
	public function new(getConfig, clientFactory) {
		this.getConfig = getConfig;
		this.clientFactory = clientFactory;
	}
	
	public function connect():Promise<Noise> {
		if(client != null && client.isConnected.value) return new Error('Already connected');
		client = clientFactory(getConfig);
		isConnected = client.isConnected;
		messageReceived = client.messageReceived;
		errors = client.errors.join(errorTrigger = Signal.trigger());
		isConnected = client.isConnected;
		return tryConnect();
	}
	
	var link:CallbackLink;
	function tryConnect(delay = 10):Promise<Noise> {
		return client.connect().map(function(o) {
			switch o {
				case Success(_):
					if(link != null) link.dissolve();
					
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
	
	public function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS> {
		return Future.async(function(cb) {
			subscriptions.push(Subscribe(topic, options));
			whenConnected(function() client.subscribe(topic, options).handle(cb));
		}, false);
	}
	
	public function unsubscribe(topic:String):Promise<Noise> {
		return Future.async(function(cb) {
			subscriptions.push(Unsubscribe(topic));
			whenConnected(function() client.unsubscribe(topic).handle(cb));
		}, false);
	}
	
	public function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise> {
		return Future.async(function(cb) {
			whenConnected(function() client.publish(topic, message, options).handle(cb));
		}, false);
	}
	
	public function close(?force:Bool):Future<Noise> {
		return Future.async(function(cb) {
			whenConnected(function() client.close(force).handle(cb));
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