package ;

import tink.testrunner.*;
import tink.unit.*;
import haxe.io.Bytes;
import asys.io.*;
import mqtt.clients.*;

using tink.CoreApi;

@:asserts
@:timeout(600000)
class RunTests {

  static function main() {
    Runner.run(TestBatch.make([
      new RunTests(),
    ])).handle(Runner.exit);
  }
  
  function new() {}
  
  function killAll() {
    return Future.async(function(cb) {
      function check()
        return Promise.ofJsPromise(js.Lib.require('find-process')('port', 1883))
          .next(function(list:Array<{pid:String}>) {
              for(p in list) Sys.command('kill', [p.pid]);
              return list.length;
          });
      
      function recheck()
        check().handle(function(o) switch o {
          case Success(0): cb(Success(Noise));
          case Success(_): recheck();
          case Failure(e): cb(Failure(e));
        });
        
      recheck();
    });
  }
  
  function runBroker() {
    return killAll()
      .next(function(_) {
        var proc = new Process('npm', ['run', 'mosca']);
        proc.stderr.all().handle(function(o) switch o.sure().toString() {
          case '': 
          case v: trace(v);
        });
        return Future.async(function(cb) {
          function check() {
            Promise.ofJsPromise(js.Lib.require('find-process')('port', 1883))
              .handle(function(o) switch o {
                case Success(list) if(list.length == 0): haxe.Timer.delay(check, 100);
                case Success(_): cb(Success(proc));
                case Failure(e): cb(Failure(e));
              });
          }
          check();
        });
      });
  }
  
  public function echo() {
    runBroker()
      .handle(function(o) switch o {
        case Success(broker):
          var client = new NodeClient('mqtt://localhost');
          client.connect()
            .handle(function(o) switch o {
              case Success(_):
                var count = 0;
                var topic = 'haxe-mqtt-' + Date.now().getTime();
                client.message.handle(function(m) {
                  asserts.assert(m.a == topic);
                  asserts.assert(m.b == 'after');
                  if(++count == 3) {
                    asserts.done();
                  }
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
        case Failure(e):
          asserts.fail(e);
      });
      
      return asserts;
  }
  
  @:include
  public function retry() {
    runBroker()
      .handle(function(o) switch o {
        case Success(broker):
          var client = new KeepAliveClient('mqtt://localhost', NodeClient.new);
          client.connect()
            .handle(function(o) switch o {
              case Success(_):
                var count = 0;
                var topic = 'haxe-mqtt-' + Date.now().getTime();
                client.message.handle(function(m) {
                  asserts.assert(m.a == topic);
                  asserts.assert(m.b == 'after');
                  if(++count == 3) {
                    asserts.done();
                  }
                });
                client.publish(topic, 'before');
                client.publish(topic, 'before');
                client.publish(topic, 'before');
                client.subscribe(topic);
                client.publish(topic, 'after');
                runBroker().handle(function(_) {
                  trace('broker up');
                  client.publish(topic, 'after');
                  client.publish(topic, 'after');
                });
              case Failure(e):
                asserts.fail(e);
            });
        case Failure(e):
          asserts.fail(e);
      });
      return asserts;
  }
}