package zeno;

import zeno.Assert;
import zeno.math.TestFPNumber;
import zeno.math.TestFPMath;
import zeno.math.TestFPVector;
import zeno.ecs.TestEntityManager;
import zeno.ecs.TestQuery;
import zeno.geom.TestGJK;
import zeno.geom.TestEPA;
import zeno.spatial.TestDynamicBVH;
import zeno.physics.TestConstraints;
import zeno.physics.TestJoints;
import zeno.rollback.TestRollbackIdempotency;
import zeno.net.TestJitterBuffer;
import zeno.replay.TestReplayStream;

class TestMain {
    public static function main() {
        #if sys
        Sys.println("\n================================================================================");
        Sys.println("  ZENO DETERMINISTIC SIMULATION ENGINE: FULL VERIFICATION PASS");
        Sys.println("================================================================================");
        #end

        TestFPNumber.run();
        TestFPMath.run();
        TestFPVector.run();
        TestEntityManager.run();
        TestQuery.run();
        TestGJK.run();
        TestEPA.run();
        TestDynamicBVH.run();
        TestConstraints.run();
        TestJoints.run();
        TestRollbackIdempotency.run();
        TestJitterBuffer.run();
        TestReplayStream.run();

        var success = Assert.summary();
        #if sys
        if (!success) {
            Sys.exit(1);
        }
        #end
    }
}
