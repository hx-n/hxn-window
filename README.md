# hxn-window

Windowing and surfaces for Haxe, on HashLink, Ash, hxcpp and CPPIA. A
program opens windows and takes their events: keyboard and text input,
mouse, touch, gestures and dropped files. It also sets cursors, reads
monitors and their video modes, uses the clipboard and polls gamepads. Each
window hands a GPU library the native handles it needs for a surface to
render into.

The same program compiles for HashLink and for hxcpp.

```haxe
import window.Window;
import window.WindowAttributes;

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
```

## The API

The classes are in the package `window`:

| Class | What it is |
|---|---|
| `WindowAttributes` | What a window opens with: title, size, position, decorations, transparency, level, theme, icon. |
| `Window` | An open window: its events from `poll` and `wait`, its size, position, state and cursor, and the clipboard. |
| `Event` | One event, such as `Closed`, `Resized`, `KeyboardInput`, `MouseInput`, `Touch` or `Ime`; `None` when none came in time. |
| `Monitor`, `VideoMode` | The displays a window can be on, and the modes they run at. |
| `Gamepad` | Connected gamepads, their buttons and axes, and their events. |

`Window.wait` lets the runtime collect garbage while it waits. A failure the
platform reports is thrown as a Haxe exception.

## A surface to render into

A window reaches a GPU library as a platform code and four integers, its
native window and display handles:

```haxe
var platform = window.platform();
var handles = [for (which in 0...4) window.raw(which)];
```

The codes are 1 AppKit, 2 Win32, 3 Xlib, 4 Wayland, 5 Android and 6 UIKit.
xgpu's `GpuInstance.surface` takes the code and the four integers directly.

## Runtimes

| Runtime | Status |
|---|---|
| Ash (hybrid, JIT, interpreter) | Runs `tests/run.sh` on macOS. |
| hxcpp | Runs `tests/run.sh` on macOS. |
| CPPIA | Runs `tests/run.sh` on macOS. |
| HashLink | Not run yet. |
| Linux, Windows | Not run yet. |
| Android, iOS | Not run yet. |
| wasm | Not built yet. |

## Using it

Install the `hxn` command (see [hxn](https://github.com/hx-n/hxn)'s readme),
Rust and Haxe 4.3. In this directory:

```
hxn run hl              # HashLink, or --vm ash
hxn run cpp             # hxcpp
hxn package --out ../xwindow-haxelib
```

`hxn package` writes a haxelib named `xwindow`, which a program uses with
`-lib xwindow`.

## How the API is generated

The window API is declared once, in
[xwindow](https://github.com/rayzor-blade/xwindow), which also has the native
backend over winit. `build.rs` installs that backend, and
[x-idl](https://github.com/rayzor-blade/x-idl)'s hxn target writes the
binding from the declaration: carriers over plain Rust, x-idl's model of the
API, and over it the Rust items [hxn](https://github.com/hx-n/hxn) reads.

`hxn build` runs the build script first and reads the binding from its
output. It then generates the adapter for the runtime and the Haxe classes.
A change to the API is made in xwindow's declaration, and reaches this
library when its xwindow revision is updated.

## Developing against checkouts

To build against local checkouts of hxn, x-idl and xwindow beside this one,
put `[patch]` tables for their git URLs in `.cargo/config.toml`, which git
ignores. The tests run with:

```
tests/run.sh hl ash
tests/run.sh cpp
tests/run.sh cppia
```

## License

Apache-2.0. xwindow and x-idl are MIT.
