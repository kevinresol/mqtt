package mqtt;

typedef PublishOptions = {
	?qos:QoS,
	?retain:Bool,
	?duplicate:Bool,
}