package zeno.rollback;

import zeno.Assert;
import zeno.Zeno;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.geom.CircleShape;
import zeno.geom.BoxShape;
import zeno.physics.BodyType;

/**
 * Crucial Invariant Test: Rollback Idempotency.
 * Proves mathematically and empirically that a simulation subjected to multiple
 * speculative rollbacks produces the exact same bit-level state hash as a simulation
 * that never rolled back at all.
 */
class TestRollbackIdempotency {
    public static function run(): Void {
        Assert.suite("Rollback Idempotency & Determinism Invariant");

        var ticks = 60;
        var seed = 4242;

        // Run 1: Ground Truth (No Rollbacks)
        var engineGroundTruth = new Zeno(seed, 2, 60);
        setupWorld(engineGroundTruth);

        var groundTruthHash = 0;
        for (t in 0...ticks) {
            // Player 0 input
            var inputP0 = (t % 5 == 0) ? 1 : 0;
            // Player 1 input: at frame 20, special input 0xFF
            var inputP1 = (t == 20) ? 0xFF : ((t % 3 == 0) ? 2 : 0);

            engineGroundTruth.rollback.setLocalInput(0, inputP0);
            engineGroundTruth.rollback.setLocalInput(1, inputP1);

            var s = engineGroundTruth.step();
            if (t == ticks - 1) {
                groundTruthHash = s.checksum;
            }
        }

        // Run 2: Rollback Stress Run (Late Mispredicted Remote Input Injected at tick 25 for tick 20)
        var engineRollback = new Zeno(seed, 2, 60);
        setupWorld(engineRollback);

        var rollbackHash = 0;
        for (t in 0...ticks) {
            var inputP0 = (t % 5 == 0) ? 1 : 0;
            engineRollback.rollback.setLocalInput(0, inputP0);

            // Normal remote input feed for Player 1: frame 20 is delayed in transit across network!
            if (t != 20) {
                var inputP1 = (t % 3 == 0) ? 2 : 0;
                engineRollback.rollback.onRemoteInput(1, t, inputP1, engineRollback.fixedDeltaTime);
            }

            // At tick 25, delayed packet arrives stating Player 1 inputted 0xFF at frame 20!
            if (t == 25) {
                engineRollback.rollback.onRemoteInput(1, 20, 0xFF, engineRollback.fixedDeltaTime);
            }

            var s = engineRollback.step();
            if (t == ticks - 1) {
                rollbackHash = s.checksum;
            }
        }

        Assert.isTrue(engineRollback.rollback.getTotalRollbacks() > 0, "Rollback engine must have executed rollbacks during the test run");
        Assert.equals(groundTruthHash, rollbackHash, "Final state hash after rollbacks must match Ground Truth state hash bit-for-bit");
    }

    private static function setupWorld(engine: Zeno): Void {
        // Static boundary
        engine.spawnBody(
            BoxShape.make(FPNumber.fromInt(20), FPNumber.ONE),
            BodyStatic,
            new FPVector2(FPNumber.ZERO, FPNumber.fromInt(-5))
        );

        // Dynamic bodies
        for (i in 0...10) {
            var x = FPNumber.fromInt(i * 2 - 10);
            var y = FPNumber.fromInt(5 + i);
            engine.spawnBody(
                new CircleShape(FPNumber.HALF),
                BodyDynamic,
                new FPVector2(x, y)
            );
        }
    }
}
