package mqtt;

import tink.Url;

using tink.CoreApi;

typedef Config = {
	uri:Url,
	?clientId:String,
	?version:Version,
	?connectTimeoutMs:Int,
	?username:String,
	?password:String,
	?ca:String,
	?cert:String,
	?key:String,
	?topics:Array<SubscribedTopic>,
}

@:enum abstract Version(Int) to Int {
	var V3 = 3;
	var V4 = 4;
}

@:callable
abstract ConfigGenerator(Void->Promise<Config>) from Void->Promise<Config> to Void->Promise<Config> {
	@:from
	public static inline function fromString(url:String):ConfigGenerator
		return fromUrl(url);
	
	@:from
	public static inline function fromSync(config:Config):ConfigGenerator
		return Promise.resolve.bind(config);
	
	@:from
	public static inline function fromSyncFunction(f:Void->Config):ConfigGenerator
		return function() return Promise.resolve(f());
	
	@:from
	public static function fromUrl(url:Url):ConfigGenerator
		return function():Promise<Config> return {
			uri: Url.make({ // re-make the url without auth
				path: url.path,
				query: url.query,
				host: url.host,
				scheme: url.scheme,
				hash: url.hash,
			}),
			username: url.auth == null ? null : url.auth.user,
			password: url.auth == null ? null : url.auth.password,
		};
}

@:forward
abstract SubscribedTopic({topic:String, qos:QoS}) from {topic:String, qos:QoS} to {topic:String, qos:QoS} {
	@:from public static inline function ofTopic(topic:String)
		return {topic: topic, qos: null}
}