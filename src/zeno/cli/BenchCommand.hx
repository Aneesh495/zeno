package zeno.cli;

import zeno.bench.BenchmarkRunner;

/**
 * Benchmark runner CLI command.
 */
class BenchCommand {
    public static function run(args: Array<String>): Void {
        BenchmarkRunner.main();
    }
}
