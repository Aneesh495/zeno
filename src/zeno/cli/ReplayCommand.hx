package zeno.cli;

import zeno.replay.ReplayReader;
import zeno.replay.ReplayStream;
import zeno.core.Buffer;

/**
 * Replay inspector and validator CLI command.
 */
class ReplayCommand {
    public static function run(args: Array<String>): Void {
        #if sys
        Sys.println("\n[Zeno Replay] Replay Stream Subsystem Ready.");
        if (args.length == 0) {
            Sys.println("Usage: zeno replay <replay-file.znr>\n");
            return;
        }

        var path = args[0];
        if (!sys.FileSystem.exists(path)) {
            Sys.println("Error: Replay file not found: " + path);
            return;
        }

        var bytes = sys.io.File.getBytes(path);
        var buf = Buffer.wrap(bytes);
        var reader = new ReplayReader(buf);

        if (reader.header == null) {
            Sys.println("Error: Invalid or corrupt Zeno replay file.");
            return;
        }

        Sys.println("  Replay Version : " + reader.header.version);
        Sys.println("  Initial Seed   : " + reader.header.initialSeed);
        Sys.println("  Player Count   : " + reader.header.playerCount);
        Sys.println("  Tick Rate      : " + reader.header.tickRateHz + " Hz");
        Sys.println("  Total Frames   : " + reader.getFrameCount() + "\n");
        #end
    }
}
