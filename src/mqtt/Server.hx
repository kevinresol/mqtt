package mqtt;

import tink.Chunk;
using tink.CoreApi;

interface Server {
	var clientConnected(default, null):Signal<ConnectedClient>;
	var messageReceived(default, null):Signal<Message>;
	function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise>;
	function close():Future<Noise>;
}

interface ConnectedClient {
	var closed(default, null):Future<Noise>;
	function close():Future<Noise>;
}