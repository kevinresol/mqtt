package mqtt;

using tink.CoreApi;
import tink.state.*;
import tink.Chunk;

interface Client {
	var message(default, null):Signal<Pair<String, Chunk>>;
	var error(default, null):Signal<Error>;
	var isConnected(default, null):Observable<Bool>;
	function connect():Promise<Noise>;
	function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS>;
	function unsubscribe(topic:String):Promise<Noise>;
	function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise>;
	function close(?force:Bool):Future<Noise>;
}

class BaseClient implements Client {
	public var message(default, null):Signal<Pair<String, Chunk>>;
	public var error(default, null):Signal<Error>;
	public var isConnected(default, null):Observable<Bool>;
	var messageTrigger(default, null):SignalTrigger<Pair<String, Chunk>>;
	var errorTrigger(default, null):SignalTrigger<Error>;
	var isConnectedState(default, null):State<Bool>;
	
	public function new() {
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

typedef SubscribeOptions = {
	?qos:QoS,
}

typedef PublishOptions = {
	?qos:QoS,
	?retain:Bool,
	?duplicate:Bool,
}