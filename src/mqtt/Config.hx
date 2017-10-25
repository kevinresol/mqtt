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
}

@:enum abstract Version(Int) to Int {
	var V3 = 3;
	var V4 = 4;
}

@:callable
abstract ConfigGenerator(Void->Promise<Config>) from Void->Promise<Config> to Void->Promise<Config> {
	@:from
	public static inline function fromString(url:String):ConfigGenerator
		return function():Promise<Config> return {uri: Url.parse(url)};
	
	@:from
	public static inline function fromUrl(url:Url):ConfigGenerator
		return function():Promise<Config> return {uri: url};
}