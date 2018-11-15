
import mqtt.*;
import mqtt.clients.*;
import mqtt.servers.*;

using tink.CoreApi;

class Playground {
	static function main() {
		trace('start');
		
		var server = new NodeServer();
		// server.clientConnected.handle(function(client) trace('client connected'));
		// server.messageReceived.handle(function(message) {
		// 	trace(message.b.toHex());
		// });
		
		haxe.Timer.delay(function() {
			var mqtt = new NodeClient('mqtt://localhost:1883');
			mqtt.connect().handle(function(o) switch o {
				case Success(_):
					// trace('connected');
					var topic = 'haxe/' + Date.now().getTime();
					mqtt.subscribe(topic);
					mqtt.publish(topic, 'test');
					mqtt.message.handle(function(o) trace(o.a, o.b.length, o.b.toHex()));
					var message = haxe.io.Bytes.alloc(10);
					for(i in 0...message.length) message.set(i, i);
					mqtt.publish(topic, message);
					
				case Failure(e):
					// trace(e);
			});
		}, 100);
	}
}