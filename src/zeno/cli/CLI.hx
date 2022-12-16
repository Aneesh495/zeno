package zeno.cli;

/**
 * Zeno CLI Command Line Interface.
 */
class CLI {
    public static function main() {
        #if sys
        var args = Sys.args();
        runWithArgs(args);
        #elseif js
        var isNode = js.Syntax.code("typeof process !== 'undefined' && process.argv !== undefined");
        if (isNode) {
            var nodeArgs: Array<String> = js.Syntax.code("process.argv.slice(2)");
            runWithArgs(nodeArgs);
        } else {
            trace("Zeno Simulation Engine initialized in browser.");
        }
        #else
        trace("Zeno CLI initialized.");
        #end
    }

    public static function runWithArgs(args: Array<String>): Void {
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
                println("Unknown command: " + cmd);
                printUsage();
        }
    }

    public static function println(msg: String): Void {
        #if sys
        Sys.println(msg);
        #elseif js
        var isNode = js.Syntax.code("typeof process !== 'undefined' && process.stdout !== undefined");
        if (isNode) {
            js.Syntax.code("console.log({0})", msg);
        } else {
            trace(msg);
        }
        #else
        trace(msg);
        #end
    }

    private static function printUsage(): Void {
        println("================================================================================");
        println("  ZENO: Deterministic Simulation & Rollback Netcode Engine");
        println("================================================================================");
        println("Usage: zeno <command> [options]\n");
        println("Commands:");
        println("  sim       Run headless physical simulation and rollback stress test");
        println("  bench     Execute comprehensive performance microbenchmarks");
        println("  replay    Inspect or verify a recorded simulation replay file (.znr)");
        println("  help      Display command line usage and system information\n");
        println("Examples:");
        println("  haxe build.hxml                   (Execute default simulation)");
        println("  haxe test.hxml                    (Run complete verification test suite)");
        println("  haxe bench.hxml                   (Run performance microbenchmarks)");
        println("================================================================================\n");
    }
}
