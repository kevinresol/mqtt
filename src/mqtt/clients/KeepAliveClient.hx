package mqtt.clients;

import haxe.Timer;

using tink.state.*;
using tink.CoreApi;

class KeepAliveClient implements Client {
	
	var subscriptions:Array<Subscription>;
	var client:Client;
	var connect:Void->Promise<Client>;
	
	
	public var message(default, null):Signal<Pair<String, Chunk>>;
	public var error(default, null):Signal<Error>;
	public var isConnected(default, null):Observable<Bool>;
	
	public var messageTrigger(default, null):SignalTrigger<Pair<String, Chunk>>;
	public var errorTrigger(default, null):SignalTrigger<Error>;
	public var isConnectedState(default, null):State<Bool>;
	
	
	public function new(connect:Void->Promise<Client>) {
		topics = [];
		message = messageTrigger = Signal.trigger();
		error = errorTrigger = Signal.trigger();
		isConnected = (isConnectedState = new State(false)).observe();
		
		this.connect = connect;
		
		tryConnect();
	}
	
	var link:CallbackLink;
	function tryConnect(delay = 10) {
		connect().handle(function(o) switch o {
			case Success(client):
				this.client = client;
				for(sub in subscriptions) switch sub {
					case Subscribe(topic, options): client.subscribe(topic, options);
					case Unsubscribe(topic): client.unsubscribe(topic);
				}
				if(link != null) link.dissolve();
				link = client.isConnected.bind(isConnectedState.set)
					&& client.message.handle(messageTrigger.trigger)
					&& client.error.handle(errorTrigger.trigger);
				client.isConnected.nextTime(function(v) return !v)
					.handle(tryConnect);
				
			case Failure(e):
				errorTrigger.trigger(e);
				Timer.delay(tryConnect.bind(delay *= 2), delay);
		});
	}
	
	public function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS> {
		return Future.async(function(cb) {
			subscriptions.push(Subsribe(topic, options));
			whenConnected(function() client.subscribe(topic, options).handle(cb));
		});
	}
	
	public function unsubscribe(topic:String):Promise<Noise> {
		return Future.async(function(cb) {
			subscriptions.remove(Unsubscribe(topic));
			whenConnected(function() client.unsubscribe(topic).handle(cb));
		});
	}
	
	public function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise> {
		return Future.async(function(cb) {
			whenConnected(function() client.publish(topic, message, options).handle(cb));
		});
	}
	
	public function close(?force:Bool):Future<Noise> {
		return Future.async(function(cb) {
			whenConnected(function() client.close(force).handle(cb));
		});
	}
	
	function whenConnected(f:Void->Void) {
		isConnected.nextTime({butNotNow: false}, function(v) return v).handle(f);
	}
}

enum Subscription {
	Subscribe(topic:String, options:SubscribeOptions);
	Unsubscribe(topic:String);
}