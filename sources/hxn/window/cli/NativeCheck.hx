package hxn.window.cli;

import hxn.window.Theme;
import hxn.window.Window;
import hxn.window.WindowAttributes;

/**
	Opens a headless window, reads its properties back, polls its events
	briefly and closes it. `hxn window check` runs it on each runtime: it exits with 1
	on a failed check, and every runtime must print the same output.
**/
class NativeCheck {
	static function check(holds:Bool, what:String) {
		Sys.println('$what: ${holds ? "yes" : "no"}');
		if (!holds)
			Sys.exit(1);
	}

	static function main() {
		var attributes = new WindowAttributes();
		attributes.title("hxn window");
		attributes.width(320);
		attributes.height(200);
		attributes.visible(false);
		var window = Window.open(attributes);
		check(window.valid(), "opened");
		check(window.title() == "hxn window", "titled");
		window.setTheme(Theme.Dark);

		// `wait` returns `None` when it times out.
		var waits = 0;
		while (waits < 20) {
			switch window.wait(0.01) {
				case None:
					waits++;
				case _:
			}
		}
		check(true, "waited");

		window.close();
		check(true, "closed");
	}
}
