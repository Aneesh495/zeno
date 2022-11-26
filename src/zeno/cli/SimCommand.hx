package zeno.cli;

import zeno.Zeno;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.geom.CircleShape;
import zeno.geom.BoxShape;
import zeno.physics.BodyType;

/**
 * Headless simulation runner and rollback stress test CLI command.
 */
class SimCommand {
    public static function run(args: Array<String>): Void {
        #if sys
        Sys.println("\n[Zeno Sim] Initializing Deterministic Simulation Environment...");

        var ticks = 300; // 5 seconds at 60Hz
        if (args.length > 0 && Std.parseInt(args[0]) != null) {
            ticks = Std.parseInt(args[0]);
        }

        var engine = new Zeno(1337, 2, 60);

        // Ground barrier
        var ground = engine.spawnBody(
            BoxShape.make(FPNumber.fromInt(100), FPNumber.fromInt(2)),
            BodyStatic,
            new FPVector2(FPNumber.ZERO, FPNumber.fromInt(-5))
        );

        // Spawn dynamic bodies
        var numBodies = 50;
        for (i in 0...numBodies) {
            var x = FPNumber.fromInt((i % 10) * 2 - 10);
            var y = FPNumber.fromInt(5 + Std.int(i / 10) * 3);
            var shape = (i % 2 == 0)
                ? cast(new CircleShape(FPNumber.fromFloat(0.5)), zeno.geom.Shape)
                : cast(BoxShape.make(FPNumber.ONE, FPNumber.ONE), zeno.geom.Shape);
            engine.spawnBody(shape, BodyDynamic, new FPVector2(x, y));
        }

        Sys.println("[Zeno Sim] Spawned " + numBodies + " dynamic rigid bodies and ground boundary.");
        Sys.println("[Zeno Sim] Running " + ticks + " simulation ticks with speculative rollback injection...");

        var rollbacksTriggered = 0;
        var start = Sys.time();

        for (t in 0...ticks) {
            // Submit local input (Player 0)
            engine.rollback.setLocalInput(0, (t % 4 == 0) ? 1 : 0);

            // Periodically inject delayed remote input (Player 1) triggering rollback
            if (t > 10 && t % 30 == 0) {
                var delayedFrame = t - 8;
                var unexpectedInput = 0xFF;
                var causedRollback = engine.rollback.onRemoteInput(1, delayedFrame, unexpectedInput, engine.fixedDeltaTime);
                if (causedRollback) rollbacksTriggered++;
            }

            var snapshot = engine.step();

            if (t % 60 == 0) {
                Sys.println("  Tick " + StringTools.lpad(Std.string(t), " ", 4) + " | Entities: " + engine.world.getEntityCount() +
                            " | Rollbacks: " + engine.rollback.getTotalRollbacks() +
                            " | State Hash: " + StringTools.hex(snapshot.checksum, 8));
            }
        }

        var elapsed = Sys.time() - start;
        var fps = Math.round(ticks / elapsed);

        Sys.println("\n[Zeno Sim] Simulation completed successfully!");
        Sys.println("  Total Ticks Simulated : " + ticks);
        Sys.println("  Total Rollbacks       : " + engine.rollback.getTotalRollbacks());
        Sys.println("  Frames Resimulated    : " + engine.rollback.getTotalResimulatedFrames());
        Sys.println("  Elapsed Wall Clock    : " + Math.round(elapsed * 1000.0) / 1000.0 + "s (" + fps + " ticks/sec)\n");
        #end
    }
}
