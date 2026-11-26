package hxn.window.cli;

import haxe.io.Path;
import hxn.cli.Context;
import hxn.cli.Failure;
import sys.FileSystem;

/**
	Opens a window with the installed package and checks its events and
	handles. Natively, the check runs on HashLink or Ash, or as an hxcpp
	program. With `--wasm --browser`, it runs in a web page in Chrome, which
	`HXN_BROWSER` can name.
**/
class CheckCommand implements hxn.cli.Command {
	/** The runtime. **/
	@:arg @:choices("hl", "cpp") var runtime = "hl";

	/** Compiles the check to wasm. **/
	@:option var wasm = false;

	/** Runs the wasm check with threads. Ash needs them for a browser window. **/
	@:option var threads = false;

	/** Runs the wasm check in a web page. **/
	@:option var browser = false;

	/** The VM that runs HashLink bytecode, with its options. The default is `hl`, and `ash` for wasm. **/
	@:option @:env("HXN_VM") @:value("command") var vm:Null<String>;

	public function run(context:Context):Int {
		if (browser != wasm)
			throw new Failure("a browser window check needs --wasm --browser", 2);
		if (threads && !wasm)
			throw new Failure("--threads needs --wasm", 2);
		if (wasm && runtime == "hl" && !threads)
			throw new Failure("Ash browser windows need --threads", 2);
		var vm = this.vm != null ? this.vm : wasm ? "ash" : "hl";
		var vmWords = ~/\s+/g.split(vm).filter(word -> word.length > 0);
		var host = vmWords.shift();
		var mode = runtime + (wasm ? "-wasm" : "") + (threads ? "-threads" : "");
		var out = Path.join([context.cwd, "target", "hxn-window", "check", mode]);
		FileSystem.createDirectory(out);
		var main = wasm ? "hxn.window.cli.BrowserCheck" : "hxn.window.cli.NativeCheck";
		var flags = [
			"-lib",
			"hxn",
			"-lib",
			"hxn-window",
			"-cp",
			Path.join([context.root, "sources"]),
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
			return 0;
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
			Path.join([context.root, "sources", "hxn", "window", "cli", "page.mjs"]),
			runtime == "hl" ? host : "emcc",
			out,
			chrome
		]);
		return 0;
	}

	static function execute(command:String, args:Array<String>) {
		var status = Sys.command(command, args);
		if (status != 0)
			throw new Failure('$command failed with status $status', status);
	}
}
