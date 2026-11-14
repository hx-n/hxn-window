import window.Window;
import window.WindowAttributes;

/** Opens a window and logs resizes until it is closed. **/
class Main {
	static function main() {
		var attributes = new WindowAttributes();
		attributes.title("Hello");
		attributes.width(800);
		attributes.height(600);
		var window = Window.open(attributes);
		var open = true;
		while (open) {
			switch window.wait(-1) {
				case Closed:
					open = false;
				case Resized(width, height):
					trace('now $width x $height');
				case _:
			}
		}
		window.close();
	}
}
