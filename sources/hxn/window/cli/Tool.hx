package hxn.window.cli;

import haxe.io.Path;
import hxn.cli.Cli;
import hxn.cli.Failure;
import hxn.cli.Reply;

/**
	The hxn command's extension for hxn-window: `hxn window doctor` and `hxn
	window check`. Before hxn builds or checks hxn-window itself, the hook
	runs `cargo check`, which writes the browser agent into `page/`.
**/
class Tool {
	static function main()
		hxn.cli.Plugin.main(new Cli("hxn window", "Checks the installed hxn-window package.", [new DoctorCommand(), new CheckCommand()]), hook);

	static function hook(phase:String, request:Dynamic):Null<Reply> {
		if ((phase != "before-build" && phase != "before-check") || request.context.project.library != "xwindow")
			return null;
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
			throw new Failure('cargo check failed with status $status', status);
		return null;
	}
}
