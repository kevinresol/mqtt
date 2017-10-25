package ;

import tink.testrunner.*;
import tink.unit.*;
import mqtt.clients.*;

using tink.CoreApi;

@:asserts
class RunTests {

  static function main() {
    Runner.run(TestBatch.make([
      new RunTests(),
    ])).handle(Runner.exit);
  }
  
  function new() {}
  
  public function echo() {
    // var client = new KeepAliveClient('mqtt://test.mosquitto.org', NodeClient.new);
    var client = new NodeClient('mqtt://test.mosquitto.org');
    client.connect()
      .handle(function(o) switch o {
        case Success(_):
          var count = 0;
          var topic = 'haxe-mqtt-' + Date.now().getTime();
          client.message.handle(function(m) {
            asserts.assert(m.a == topic);
            asserts.assert(m.b == 'after');
            if(++count == 3) asserts.done();
          });
          client.publish(topic, 'before');
          client.publish(topic, 'before');
          client.publish(topic, 'before');
          client.subscribe(topic);
          client.publish(topic, 'after');
          client.publish(topic, 'after');
          client.publish(topic, 'after');
        case Failure(e):
          asserts.fail(e);
      });
    return asserts;
  }
}