package zeno.bench;

/**
 * Microbenchmark execution and reporting harness.
 */
class BenchmarkRunner {
    public static function timeMicroseconds(action: Void -> Void): Float {
        #if sys
        var start = Sys.time();
        action();
        var elapsed = Sys.time() - start;
        return elapsed * 1000000.0;
        #else
        var start = haxe.Timer.stamp();
        action();
        var elapsed = haxe.Timer.stamp() - start;
        return elapsed * 1000000.0;
        #end
    }

    public static function runSuite(name: String, benchmarks: Array<{name: String, run: Void -> Float}>): Void {
        #if sys
        Sys.println("================================================================================");
        Sys.println("BENCHMARK SUITE: " + name);
        Sys.println("================================================================================");
        for (b in benchmarks) {
            var score = b.run();
            Sys.println(StringTools.rpad(b.name, " ", 45) + " : " + score + " ops/sec");
        }
        Sys.println("--------------------------------------------------------------------------------\n");
        #else
        trace("BENCHMARK SUITE: " + name);
        for (b in benchmarks) {
            var score = b.run();
            trace(b.name + " : " + score + " ops/sec");
        }
        #end
    }

    public static function main() {
        #if sys
        Sys.println("\nStarting Zeno Engine Performance Benchmarks...\n");
        #end
        ECSBenchmark.run();
        PhysicsBenchmark.run();
        RollbackBenchmark.run();
        #if sys
        Sys.println("All benchmark suites completed successfully.\n");
        #end
    }
}
