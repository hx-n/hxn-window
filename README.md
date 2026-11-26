# hxn-window

[![Ash](https://github.com/hx-n/hxn-window/actions/workflows/ash.yml/badge.svg)](https://github.com/hx-n/hxn-window/actions/workflows/ash.yml)
[![HashLink](https://github.com/hx-n/hxn-window/actions/workflows/hashlink.yml/badge.svg)](https://github.com/hx-n/hxn-window/actions/workflows/hashlink.yml)
[![hxcpp](https://github.com/hx-n/hxn-window/actions/workflows/hxcpp.yml/badge.svg)](https://github.com/hx-n/hxn-window/actions/workflows/hxcpp.yml)
[![CPPIA](https://github.com/hx-n/hxn-window/actions/workflows/cppia.yml/badge.svg)](https://github.com/hx-n/hxn-window/actions/workflows/cppia.yml)

A windowing and surface API for Haxe on HashLink, Ash, hxcpp and CPPIA,
using winit natively and a shared DOM agent in the browser. Windows expose
the handles a GPU needs to create a surface.

```haxe
import hxn.window.Window;
import hxn.window.WindowAttributes;

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
Linux x86-64 and ARM64, macOS arm64 and Windows x86-64, and as static
libraries for Intel macOS (hxcpp only), iOS, the iOS simulator and Android
arm64 and x86-64, so a program needs no Rust. For
HashLink, the native library is copied next to the `.hl` output at compile
time. On Linux, hxcpp links against libudev for gamepads: install
`libudev-dev`. Each GitHub release also has the haxelib as a ZIP, which
`haxelib install hxn-window-<version>.zip` installs.

The generated classes are also committed to this repository, so the API can
be read here, but the native libraries are only in releases: a `haxelib git`
install compiles once a release's `native/` directory is copied into it.

CI runs each runtime on Linux, macOS and Windows, except HashLink, which runs
on Linux and Windows. The release builds the iOS and Android libraries, and
CI does not run them. Browser builds use Ash wasm or hxcpp with Emscripten. On a mobile device, hxcpp links
the static library into the program, and so does Ash for a HashLink program.
On Android, the library exports `android_main`, which a `NativeActivity` calls:
it gives the activity to the window and then runs the program's entry,
`xwindow_main`, which Ash defines in each program that it builds for Android.

## Classes

All in the package `hxn.window`:

| Class | |
|---|---|
| `WindowAttributes` | Set before `Window.open`: title, size, position, decorations, transparency, level, theme, icon. |
| `Window` | Events through `poll` and `wait`, geometry and state, cursor, IME and the clipboard. |
| `Event` | `Closed`, `Resized`, `KeyboardInput`, `MouseInput`, `Touch`, `Ime` and the rest; `None` when `wait` times out. |
| `Monitor`, `VideoMode` | Displays and their video modes. |
| `Gamepad` | Buttons, axes, rumble and their events, and the USB vendor and product ids. |

`Window.wait` is a blocking call; the GC can run while it blocks. Platform
errors are thrown as Haxe exceptions.

## Surfaces

`window.platform()` returns a platform code, and `window.raw(0)` through
`window.raw(3)` return the native window and display handles. The codes are
1 AppKit, 2 Win32, 3 Xlib, 4 Wayland, 5 Android, 6 UIKit and 7 the browser canvas. xgpu's
`GpuInstance.surface` takes the code and the four handles in that order.

## Browser builds

The installed haxelib registers its tools with hxn 0.3.7 or later. No repository checkout
or Rust compiler is needed to check a prebuilt package:

```
hxn plugins
hxn window doctor
hxn window check hl --wasm --threads --browser --vm ash
hxn window check cpp --wasm --browser
hxn window check cpp --wasm --threads --browser
```

Ash builds and serves the HashLink program with its wasm tooling. The cpp
builds use hxcpp and Emscripten. Threaded builds use shared memory; the
browser runner supplies the required isolation headers. Native checks are
`hxn window check hl --vm ash` and `hxn window check cpp`.

A browser window is the page's canvas. Size, DPI, focus, visibility,
keyboard, pointer, touch, wheel, IME and gamepad input use the same API as
native windows. The window handles DOM input and CSS sizing while the GPU
driver owns rendering and the drawing buffer. A page has one window.
Without threads, `wait` returns available events without blocking. Return
to the browser between turns, as the hello example does, and use `then`
for asynchronous results.

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
hxn package hl cpp --wasm --threads --release --out ../hxn-window-haxelib
hxn package cpp --wasm --release --out ../hxn-window-haxelib
```

The CLI's before-build hook generates the browser modules from xwindow and
x-idl. Packaging carries the CLI tool, checks and page modules with the
prebuilt libraries. Use release packages when combining threaded wasm
libraries with released GPU drivers.

To build against checkouts of hxn, x-idl and xwindow beside this one, put
`[patch]` tables for their git URLs in `.cargo/config.toml`, which git
ignores.

## Agent skill

[`skills/hxn-window/SKILL.md`](https://github.com/hx-n/hxn-window/blob/main/skills/hxn-window/SKILL.md) describes the library for coding
agents. The haxelib includes it.

## License

Apache-2.0. xwindow and x-idl are MIT.

## Third-party notices

Dependency licenses and redistribution notices are in
[third-party/NOTICES.md](https://github.com/hx-n/hxn-window/blob/main/third-party/NOTICES.md). Retain the applicable
notices when redistributing binaries.

## Logging

Diagnostics use core `hxn.Log` with target `hxn.window`. The application
can set `Log.level` and `Log.sink` to capture Haxe and native records together.
Custom frame loops drain them with `hxn.Loop.sync()`; idle background work
needs an application-driven `hxn.Log.flush()`.
