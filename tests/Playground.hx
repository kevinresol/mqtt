
import mqtt.*;
import mqtt.clients.*;

using tink.CoreApi;

class Playground {
	static function main() {
		trace('start');
		var mqtt = new JsClient('ws://localhost:3000');
		mqtt.connect().handle(function(o) switch o {
			case Success(_):
				trace('connected');
				var topic = 'haxe/' + Date.now().getTime();
				mqtt.subscribe(topic);
				// mqtt.publish(topic, 'test');
				mqtt.message.handle(function(o) trace(o.a, o.b.length, o.b.toHex()));
				var message = haxe.io.Bytes.alloc(10);
				for(i in 0...message.length) message.set(i, i);
				mqtt.publish(topic, message);
				haxe.Timer.delay(function() trace('delayed'), 500000);
			case Failure(e):
				trace(e);
		});
	}
}