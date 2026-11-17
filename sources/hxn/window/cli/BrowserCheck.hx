package hxn.window.cli;

import hxn.window.*;

/** DOM events must arrive through the public Haxe API on every browser build. **/
class BrowserCheck {
	static var window:Window;
	static var seen:Map<String, Bool> = [];
	static final required = [
		"resize",
		"redraw",
		"focus",
		"pointer",
		"button",
		"wheel",
		"key",
		"touch",
		"preedit",
		"commit",
		"hidden",
		"gamepad"
	];
	static var ticks = 0;
	static var ready = false;
	static var timer:haxe.Timer;

	static function main() {
		try
			start()
		catch (e:Dynamic) {
			Sys.println("failed: " + Std.string(e));
			hxn.Loop.exit(1);
		}
	}

	static function start() {
		var attributes = new WindowAttributes();
		attributes.title("hxn browser window");
		attributes.width(320);
		attributes.height(200);
		window = Window.open(attributes);
		attributes.close();
		if (!window.valid() || window.title() != "hxn browser window" || window.platform() != 7)
			throw "window did not open";
		window.setImeAllowed(true);
		window.requestRedraw();
		Gamepad.available();
		#if emscripten
		hxn.native.Emscripten.later(frame);
		#else
		timer = new haxe.Timer(16);
		timer.run = frame;
		#end
	}

	static function frame() {
		for (_ in 0...1000) {
			switch window.poll() {
				case Resized(w, h):
					if (haxe.Int64.toInt(w) == 800 && haxe.Int64.toInt(h) == 480)
						seen["resize"] = true;
				case RedrawRequested:
					seen["redraw"] = true;
				case Focused(true):
					seen["focus"] = true;
				case CursorMoved(x, y, _):
					if (x > 0 && y > 0)
						seen["pointer"] = true;
				case MouseInput(_, _, _):
					seen["button"] = true;
				case MouseWheel(_, _, _):
					seen["wheel"] = true;
				case KeyboardInput(_, _, _):
					seen["key"] = true;
				case Touch(_, _, _, _, _, _):
					seen["touch"] = true;
				case Ime(Preedit(text, _)):
					if (text == "に")
						seen["preedit"] = true;
				case Ime(Commit(text)):
					if (text == "日本語")
						seen["commit"] = true;
				case Ime(Enabled):
					if (!ready) {
						ready = true;
						Sys.println("browser ready");
					}
				case Occluded(true):
					seen["hidden"] = true;
				case None:
					break;
				case _:
			}
		}
		if (Gamepad.count() > 0)
			seen["gamepad"] = true;
		if (required.filter(name -> !seen.exists(name)).length == 0) {
			if (window.width() != 800 || window.height() != 480 || window.scaleFactor() != 2)
				throw "size and DPI disagree with resize events";
			Sys.println("browser events: passed");
			#if !emscripten
			timer.stop();
			#end
			window.close();
			hxn.Loop.exit(0);
		} else if (++ticks > 3000) {
			Sys.println('missing: ${required.filter(name -> !seen.exists(name)).join(", ")}');
			hxn.Loop.exit(1);
		}
		#if emscripten
		hxn.native.Emscripten.later(frame);
		#end
	}
}
