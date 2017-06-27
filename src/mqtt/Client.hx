package mqtt;

using tink.CoreApi;
import tink.Chunk;

interface Client {
	var message(default, null):Signal<Pair<String, Chunk>>;
	function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS>;
	function unsubscribe(topic:String):Promise<Noise>;
	function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise>;
	function close(?force:Bool):Future<Noise>;
}

typedef SubscribeOptions = {
	?qos:QoS,
}

typedef PublishOptions = {
	?qos:QoS,
	?retain:Bool,
	?duplicate:Bool,
}