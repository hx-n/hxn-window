package hxn.window.cli;

import haxe.Json;
import haxe.io.Path;
import hxn.cli.Context;
import hxn.cli.Failure;
import sys.FileSystem;
import sys.io.File;

/** Prints the version of the installed package and the targets that it has native libraries for. **/
class DoctorCommand implements hxn.cli.Command {
	public function run(context:Context):Int {
		var manifest:Dynamic = Json.parse(File.getContent(Path.join([context.root, "haxelib.json"])));
		Sys.println('hxn-window ${manifest.version}');
		var native = Path.join([context.root, "native"]);
		if (!FileSystem.exists(native))
			throw new Failure("this package has no prebuilt libraries");
		var targets = FileSystem.readDirectory(native);
		targets.sort(Reflect.compare);
		for (target in targets)
			Sys.println('  $target');
		return 0;
	}
}
