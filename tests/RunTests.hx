package ;

class RunTests {

  static function main() {
    mqtt.clients.NodeClient.connect('mqtt://test.mosquitto.org')
      .handle(function(o) switch o {
        case Success(client):
          client.message.handle(function(m) {
            trace(m.a, m.b.toString());
          });
          client.publish('test', 'before');
          client.publish('test', 'before');
          client.publish('test', 'before');
          client.subscribe('test');
          client.publish('test', 'after');
          client.publish('test', 'after');
          client.publish('test', 'after');
        case Failure(e):
          trace(e);
      });
    // travix.Logger.println('it works');
    // travix.Logger.exit(0); // make sure we exit properly, which is necessary on some targets, e.g. flash & (phantom)js
  }
  
}