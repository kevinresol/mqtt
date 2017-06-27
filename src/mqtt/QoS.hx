package mqtt;

@:enum
abstract QoS(Int) to Int {
	var AtMostOnce = 0;
	var AtLeastOnce = 1;
	var ExactlyOnce = 2;
}