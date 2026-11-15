# hxn-window

[![Ash](https://github.com/hx-n/hxn-window/actions/workflows/ash.yml/badge.svg)](https://github.com/hx-n/hxn-window/actions/workflows/ash.yml)
[![HashLink](https://github.com/hx-n/hxn-window/actions/workflows/hashlink.yml/badge.svg)](https://github.com/hx-n/hxn-window/actions/workflows/hashlink.yml)
[![hxcpp](https://github.com/hx-n/hxn-window/actions/workflows/hxcpp.yml/badge.svg)](https://github.com/hx-n/hxn-window/actions/workflows/hxcpp.yml)
[![CPPIA](https://github.com/hx-n/hxn-window/actions/workflows/cppia.yml/badge.svg)](https://github.com/hx-n/hxn-window/actions/workflows/cppia.yml)

A windowing and surface API for Haxe, over winit, for HashLink, Ash, hxcpp
and CPPIA. The same program compiles for each runtime, and each window
exposes its native handles for creating a GPU surface.

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

## Installing

```
haxelib install hxn-window
```

Then compile with `-lib hxn-window`, for HashLink or hxcpp:

```
haxe -lib hxn-window -main Main -hl main.hl
haxe -lib hxn-window -main Main -cpp out
```

The haxelib contains the generated classes and prebuilt native libraries for
Linux x86-64, macOS arm64 and Windows x86-64, so a program needs no Rust. For
HashLink, the native library is copied next to the `.hl` output at compile
time. On Linux, hxcpp links against libudev for gamepads: install
`libudev-dev`. Each GitHub release also has the haxelib as a ZIP, which
`haxelib install hxn-window-<version>.zip` installs.

The generated classes are also committed to this repository, so the API can
be read here, but the native libraries are only in releases: a `haxelib git`
install compiles once a release's `native/` directory is copied into it.

CI runs each runtime on Linux, macOS and Windows, except HashLink, which runs
on Linux and Windows. Android, iOS and wasm builds are not set up yet.

## Classes

All in the package `window`:

| Class | |
|---|---|
| `WindowAttributes` | Set before `Window.open`: title, size, position, decorations, transparency, level, theme, icon. |
| `Window` | Events through `poll` and `wait`, geometry and state, cursor, IME and the clipboard. |
| `Event` | `Closed`, `Resized`, `KeyboardInput`, `MouseInput`, `Touch`, `Ime` and the rest; `None` when `wait` times out. |
| `Monitor`, `VideoMode` | Displays and their video modes. |
| `Gamepad` | Buttons, axes, rumble and their events. |

`Window.wait` is a blocking call; the GC can run while it blocks. Platform
errors are thrown as Haxe exceptions.

## Surfaces

`window.platform()` returns a platform code, and `window.raw(0)` through
`window.raw(3)` return the native window and display handles. The codes are
1 AppKit, 2 Win32, 3 Xlib, 4 Wayland, 5 Android and 6 UIKit. xgpu's
`GpuInstance.surface` takes the code and the four handles in that order.

## Examples

- `examples/hello`: the program above, with `hl.hxml` and `cpp.hxml`.
- `examples/headless`: the test CI runs, which opens a headless window and
  checks its properties and events.

## How the binding is generated

The API is declared in [xwindow](https://github.com/rayzor-blade/xwindow),
along with its native backend over winit. `build.rs` installs the backend,
and [x-idl](https://github.com/rayzor-blade/x-idl)'s hxn target writes the
binding from the declaration. `hxn build` runs the build script first, then
generates each runtime's adapter and one set of Haxe classes, shared by
every runtime, from that binding.
Changing the API means changing xwindow's declaration and updating the
xwindow revision this crate pins.

## Building from source

Requires the [hxn](https://github.com/hx-n/hxn) CLI, Rust and Haxe 4.3.
`hxn check` builds the binding and runs `examples/headless` on each runtime
named, and fails unless every run passes and prints the same output.
`hxn package` writes the haxelib for this machine:

```
hxn check hl --vm ash
hxn check cpp cppia
hxn package hl cpp --out ../hxn-window-haxelib
```

To build against checkouts of hxn, x-idl and xwindow beside this one, put
`[patch]` tables for their git URLs in `.cargo/config.toml`, which git
ignores.

## Agent skill

[`skills/hxn-window/SKILL.md`](https://github.com/hx-n/hxn-window/blob/main/skills/hxn-window/SKILL.md) describes the library for coding
agents. The haxelib includes it.

## License

Apache-2.0. xwindow and x-idl are MIT.
