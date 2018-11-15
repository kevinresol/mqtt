package mqtt;

import tink.state.*;
import tink.Chunk;
import mqtt.Config;

using tink.CoreApi;

interface Client {
	var message(default, null):Signal<Message>;
	var error(default, null):Signal<Error>;
	var isConnected(default, null):Observable<Bool>;
	function connect():Promise<Noise>;
	function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS>;
	function unsubscribe(topic:String):Promise<Noise>;
	function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise>;
	function close(?force:Bool):Future<Noise>;
}

class BaseClient implements Client {
	public var message(default, null):Signal<Message>;
	public var error(default, null):Signal<Error>;
	public var isConnected(default, null):Observable<Bool>;
	var messageTrigger:SignalTrigger<Message>;
	var errorTrigger:SignalTrigger<Error>;
	var isConnectedState:State<Bool>;
	var getConfig:ConfigGenerator;
	
	public function new(getConfig) {
		this.getConfig = getConfig;
		message = messageTrigger = Signal.trigger();
		error = errorTrigger = Signal.trigger();
		isConnected = isConnectedState = new State(false);
	}
	
	public function connect():Promise<Noise> throw 'abstract';
	public function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS> throw 'abstract';
	public function unsubscribe(topic:String):Promise<Noise> throw 'abstract';
	public function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise> throw 'abstract';
	public function close(?force:Bool):Future<Noise> throw 'abstract';
	
	inline function asClient():Client return this;
}

