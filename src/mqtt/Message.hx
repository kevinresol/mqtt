package mqtt;

import tink.Chunk;
using tink.CoreApi;

abstract Message(Pair<String, Chunk>) from Pair<String, Chunk> to Pair<String, Chunk> {
	public var topic(get, never):String;
	public var content(get, never):Chunk;
	inline function get_topic() return this.a;
	inline function get_content() return this.b;
}