package hxn.window.cli;

import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/** The installed window library's hxn CLI extension. **/
class Tool {
	static function main() {
		try {
			var request:Dynamic = Json.parse(Sys.stdin().readAll().toString());
			if (request.version != 1)
				throw "unsupported hxn plugin protocol";
			var root:String = request.root;
			switch (request.kind : String) {
				case "hook":
					if ((request.phase == "before-build" || request.phase == "before-check")
						&& request.context.project.library == "xwindow") {
						var directory:String = request.context.project.directory;
						var previous = Sys.getEnv("HXN_WINDOW_PAGE_OUT");
						Sys.putEnv("HXN_WINDOW_PAGE_OUT", Path.join([directory, "page"]));
						var status = Sys.command("cargo", [
							"check",
							"--quiet",
							"--manifest-path",
							Path.join([directory, "Cargo.toml"]),
							"--target-dir",
							request.context.project.target_directory
						]);
						Sys.putEnv("HXN_WINDOW_PAGE_OUT", previous);
						if (status != 0)
							Sys.exit(status);
					}
					Sys.println('{"version":1}');
				case "command":
					var args:Array<String> = request.arguments;
					var command = args.shift();
					switch command {
						case "doctor": doctor(root);
						case "check": check(root, args);
						case null | "help" | "--help" | "-h":
							Sys.println("hxn window doctor");
							Sys.println("hxn window check <hl|cpp> [--wasm --browser] [--threads] [--vm <command>]");
						case _: throw 'unknown window command: $command';
					}
				case _:
					throw "unknown hxn plugin request";
			}
		} catch (error:Dynamic) {
			Sys.stderr().writeString('hxn-window: ${Std.string(error)}\n');
			Sys.exit(2);
		}
	}

	static function doctor(root:String) {
		var manifest:Dynamic = Json.parse(File.getContent(Path.join([root, "haxelib.json"])));
		Sys.println('hxn-window ${manifest.version}');
		var native = Path.join([root, "native"]);
		if (!FileSystem.exists(native))
			throw "this package has no prebuilt libraries";
		var targets = FileSystem.readDirectory(native);
		targets.sort(Reflect.compare);
		for (target in targets)
			Sys.println('  $target');
	}

	static function execute(command:String, args:Array<String>) {
		var status = Sys.command(command, args);
		if (status != 0)
			Sys.exit(status);
	}

	static function check(root:String, args:Array<String>) {
		var runtime = args.shift();
		if (runtime == null)
			runtime = "hl";
		if (runtime != "hl" && runtime != "cpp")
			throw "expected hl or cpp";
		var wasm = false;
		var threads = false;
		var browser = false;
		var vm:Null<String> = null;
		while (args.length > 0) {
			switch args.shift() {
				case "--wasm":
					wasm = true;
				case "--threads":
					threads = true;
				case "--browser":
					browser = true;
				case "--vm":
					vm = args.shift();
					if (vm == null)
						throw "--vm needs a command";
				case flag:
					throw 'unknown check option: $flag';
			}
		}
		if (browser != wasm)
			throw "a browser window check needs --wasm --browser";
		if (threads && !wasm)
			throw "--threads needs --wasm";
		if (wasm && runtime == "hl" && !threads)
			throw "Ash browser windows need --threads";
		if (vm == null)
			vm = Sys.getEnv("HXN_VM");
		if (vm == null)
			vm = wasm ? "ash" : "hl";
		var vmWords = ~/\s+/g.split(vm).filter(word -> word.length > 0);
		var host = vmWords.shift();
		var mode = runtime + (wasm ? "-wasm" : "") + (threads ? "-threads" : "");
		var out = Path.join([Sys.getCwd(), "target", "hxn-window", "check", mode]);
		FileSystem.createDirectory(out);
		var main = wasm ? "hxn.window.cli.BrowserCheck" : "hxn.window.cli.NativeCheck";
		var flags = [
			"-lib",
			"hxn",
			"-lib",
			"hxn-window",
			"-cp",
			Path.join([root, "sources"]),
			"-main",
			main
		];
		if (threads)
			flags = flags.concat(["-D", "hxn_threads"]);
		if (runtime == "hl") {
			flags = flags.concat(["-hl", Path.join([out, "main.hl"])]);
			if (wasm)
				flags = flags.concat(["-D", "wasm"]);
		} else {
			flags = flags.concat(["-cpp", out]);
			if (wasm)
				flags = flags.concat([
					"-D",                      "emscripten", "-D", "disable_unicode_strings",
					"-D", "HXCPP_LINK_EMSCRIPTEN_EXT=.html", "-D",        "HXCPP_LINK_EMRUN"
				]);
		}
		var cc = Sys.getEnv("CC");
		var cxx = Sys.getEnv("CXX");
		if (runtime == "cpp" && wasm) {
			Sys.putEnv("CC", null);
			Sys.putEnv("CXX", null);
		}
		execute("haxe", flags);
		Sys.putEnv("CC", cc);
		Sys.putEnv("CXX", cxx);
		if (!wasm) {
			if (runtime == "hl")
				execute(host, vmWords.concat([Path.join([out, "main.hl"])]));
			else
				execute(Path.join([out, "NativeCheck" + (Sys.systemName() == "Windows" ? ".exe" : "")]), []);
			return;
		}
		if (runtime == "hl")
			execute(host, vmWords.concat([
				"--build",
				Path.join([out, "main.wasm"]),
				"--target",
				"wasm32-wasip1-threads",
				"--native-lib",
				Path.join([out, "libxwindow.a"]),
				Path.join([out, "main.hl"])
			]));
		var chrome = Sys.getEnv("HXN_BROWSER");
		if (chrome == null)
			chrome = switch Sys.systemName() {
				case "Mac": "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
				case "Windows": Path.join([Sys.getEnv("PROGRAMFILES"), "Google", "Chrome", "Application", "chrome.exe"]);
				case _: "google-chrome";
			}
		Sys.putEnv("HXN_TEST_MAIN", "BrowserCheck");
		execute("node", [
			Path.join([root, "sources", "hxn", "window", "cli", "page.mjs"]),
			runtime == "hl" ? host : "emcc",
			out,
			chrome
		]);
	}
}
