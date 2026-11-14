# hxn-window

[xwindow](https://github.com/rayzor-blade/xwindow)'s `window` API for Haxe,
built with [hxn](https://github.com/hx-n/hxn): windows, their events,
monitors, the clipboard and gamepads, over winit.

The classes are the same as hlwindow's, in the package `window`: `Window`,
`WindowAttributes`, `Event`, `Monitor`, `Gamepad` and the rest, with the same
methods and enum values. hxn builds them for each runtime it supports from
one Rust crate, so the same program compiles for HashLink and for hxcpp.

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

## Runtimes

| Runtime | Status |
|---|---|
| Ash (hybrid, JIT, interpreter) | Runs `tests/run.sh` on macOS. |
| hxcpp | Runs `tests/run.sh` on macOS. |
| CPPIA | Runs `tests/run.sh` on macOS. |
| HashLink | Not run yet. |
| Linux, Windows | Not run yet. |
| Android, iOS | Not run yet. |
| wasm | Not built yet: xwindow's browser backend is not wired in. |

## Using it

Install the `hxn` command (see hxn's readme), Rust, and Haxe 4.3. In this
directory:

```
hxn run hl              # HashLink, or --vm ash
hxn run cpp             # hxcpp
hxn package --out ../xwindow-haxelib
```

`hxn package` writes a haxelib named `xwindow`, which a program uses with
`-lib xwindow`, as hlwindow's is used.

## How it is built

`build.rs` installs xwindow's native backend and has x-idl's hxn target write
the binding from xwindow's declaration: carriers over plain Rust, x-idl's
shared model, and over it the Rust items hxn reads. `hxn build` runs the build
script first and reads the binding from its output, then generates the
adapter and the Haxe classes for the runtime.

A failure the backend reports is thrown on the Haxe side after the call has
returned. `Window.wait` is marked as blocking, so a HashLink or Ash program
can collect while it waits.

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
