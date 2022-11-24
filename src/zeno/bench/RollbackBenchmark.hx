package zeno.bench;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.ecs.Entity;
import zeno.rollback.Snapshot;
import zeno.rollback.DeltaCompressor;
import zeno.rollback.StateHasher;
import zeno.rollback.RollbackManager;

/**
 * Microbenchmarks for rollback snapshotting, delta compression, and resimulation loops.
 */
class RollbackBenchmark {
    public static function run(): Void {
        BenchmarkRunner.runSuite("State Rollback & Resimulation Engine", [
            {
                name: "Snapshot Serialization (1,000 entities, 1,000 times)",
                run: function(): Float {
                    var s = new Snapshot(100);
                    for (i in 0...1000) {
                        s.addEntityState(
                            Entity.make(i + 1, 1),
                            new FPVector2(FPNumber.fromInt(i), FPNumber.fromInt(i)),
                            FPNumber.ZERO,
                            FPVector2.ZERO,
                            FPNumber.ZERO,
                            true
                        );
                    }

                    var count = 1000;
                    var timeUs = BenchmarkRunner.timeMicroseconds(function() {
                        for (i in 0...count) {
                            var buf = s.serialize();
                        }
                    });

                    return Math.round((count / (timeUs / 1000000.0)));
                }
            },
            {
                name: "Differential XOR-RLE State Compression (500 runs)",
                run: function(): Float {
                    var s0 = new Snapshot(0);
                    var s1 = new Snapshot(1);
                    for (i in 0...1000) {
                        s0.addEntityState(Entity.make(i + 1, 1), new FPVector2(FPNumber.fromInt(i), FPNumber.fromInt(i)), FPNumber.ZERO, FPVector2.ZERO, FPNumber.ZERO, true);
                        // Slight change for 5% of entities
                        var dy = (i % 20 == 0) ? FPNumber.ONE : FPNumber.ZERO;
                        s1.addEntityState(Entity.make(i + 1, 1), new FPVector2(FPNumber.fromInt(i), FPNumber.fromInt(i) + dy), FPNumber.ZERO, FPVector2.ZERO, FPNumber.ZERO, true);
                    }

                    var b0 = s0.serialize().toBytes();
                    var b1 = s1.serialize().toBytes();
                    var count = 500;

                    var timeUs = BenchmarkRunner.timeMicroseconds(function() {
                        for (i in 0...count) {
                            var delta = DeltaCompressor.compress(b0, b1);
                        }
                    });

                    return Math.round((count / (timeUs / 1000000.0)));
                }
            },
            {
                name: "Murmur3 State Hashing (1,000 entities, 2,000 hashes)",
                run: function(): Float {
                    var s = new Snapshot(50);
                    for (i in 0...1000) {
                        s.addEntityState(Entity.make(i + 1, 1), new FPVector2(FPNumber.fromInt(i), FPNumber.fromInt(i)), FPNumber.ZERO, FPVector2.ZERO, FPNumber.ZERO, true);
                    }

                    var count = 2000;
                    var timeUs = BenchmarkRunner.timeMicroseconds(function() {
                        for (i in 0...count) {
                            var h = StateHasher.hashSnapshot(s);
                        }
                    });

                    return Math.round((count / (timeUs / 1000000.0)));
                }
            }
        ]);
    }
}
