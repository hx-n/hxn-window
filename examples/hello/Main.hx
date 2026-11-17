import hxn.window.Event;
import hxn.window.Window;
import hxn.window.WindowAttributes;

/** Opens a window and logs resizes until it is closed. **/
class Main {
	static function main() {
		var attributes = new WindowAttributes();
		attributes.title("Hello");
		attributes.width(800);
		attributes.height(600);
		var window = Window.open(attributes);
		attributes.close();
		var open = true;
		function handle(event:Event) {
			switch event {
				case Closed:
					open = false;
				case Resized(width, height):
					trace('now $width x $height');
				case _:
			}
		}
		#if emscripten
		function turn() {
			while (open) {
				var event = window.poll();
				switch event {
					case None:
						break;
					case _:
						handle(event);
				}
			}
			if (open)
				hxn.native.Emscripten.later(turn);
			else
				window.close();
		}
		hxn.native.Emscripten.later(turn);
		#else
		while (open)
			handle(window.wait(-1));
		window.close();
		#end
	}
}
