package mqtt;

using tink.CoreApi;

class Mqtt {
	public static function isValidTopic(topic:String):Bool {
		return topic.indexOf('+') == -1 && topic.indexOf('#') == -1;
	}
	
	public static function isValidPattern(pattern:String):Bool {
		return 
			if(pattern == '#') true;
			else switch pattern.indexOf('#') {
				case -1: true;
				case i: i == pattern.length - 1 && pattern.charCodeAt(i - 1) == '/'.code; // `#` must be the last section and not combined with anything else
			}
	}
	
	public static function match(topic:String, pattern:String) {
		if(pattern == '#' || topic == pattern) return true;
		var t = topic.split('/');
		var p = pattern.split('/');
		
		for(i in 0...t.length) {
			switch p[i] {
				case '#': return true; // done
				case v if(v == '+' || v == t[i]): // ok
				case _: return false;
			}
		}
		
		return true;
	}
}