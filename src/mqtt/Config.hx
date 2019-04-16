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
	?topics:Array<String>,
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