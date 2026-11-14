import window.Event;
import window.Theme;
import window.Window;
import window.WindowAttributes;

/** Opens a window that is not shown, reads it back, takes its events for a moment and closes it. **/
class Main {
	static function main() {
		var attributes = new WindowAttributes();
		attributes.title("hxn window");
		attributes.width(320);
		attributes.height(200);
		attributes.visible(false);
		var window = Window.open(attributes);
		Sys.println('opened: ${window.valid()}');
		Sys.println('title: ${window.title()}');
		window.setTheme(Theme.Dark);

		// Every event is a value of `Event`; `None` means nothing came in time.
		var waits = 0;
		while (waits < 20) {
			switch window.wait(0.01) {
				case None:
					waits++;
				case Resized(width, height):
				case _:
			}
		}
		Sys.println("events taken");

		window.close();
		Sys.println("closed");
	}
}
