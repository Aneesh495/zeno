package zeno.cli;

/**
 * Zeno CLI Command Line Interface.
 */
class CLI {
    public static function main() {
        #if sys
        var args = Sys.args();
        if (args.length == 0) {
            printUsage();
            return;
        }

        var cmd = args[0].toLowerCase();
        switch (cmd) {
            case "sim" | "run":
                SimCommand.run(args.slice(1));
            case "bench":
                BenchCommand.run(args.slice(1));
            case "replay":
                ReplayCommand.run(args.slice(1));
            case "help" | "--help" | "-h":
                printUsage();
            default:
                Sys.println("Unknown command: " + cmd);
                printUsage();
        }
        #else
        trace("Zeno CLI initialized.");
        #end
    }

    private static function printUsage(): Void {
        #if sys
        Sys.println("================================================================================");
        Sys.println("  ZENO: Deterministic Simulation & Rollback Netcode Engine");
        Sys.println("================================================================================");
        Sys.println("Usage: zeno <command> [options]\n");
        Sys.println("Commands:");
        Sys.println("  sim       Run headless physical simulation and rollback stress test");
        Sys.println("  bench     Execute comprehensive performance microbenchmarks");
        Sys.println("  replay    Inspect or verify a recorded simulation replay file (.znr)");
        Sys.println("  help      Display command line usage and system information\n");
        Sys.println("Examples:");
        Sys.println("  haxe build.hxml                   (Execute default simulation)");
        Sys.println("  haxe test.hxml                    (Run complete verification test suite)");
        Sys.println("  haxe bench.hxml                   (Run performance microbenchmarks)");
        Sys.println("================================================================================\n");
        #end
    }
}
