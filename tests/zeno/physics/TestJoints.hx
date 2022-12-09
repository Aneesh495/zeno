package zeno.physics;

import zeno.Assert;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.physics.PhysicsWorld;
import zeno.physics.RigidBody;
import zeno.physics.Collider;
import zeno.physics.BodyType;
import zeno.geom.CircleShape;
import zeno.ecs.Entity;

/**
 * Unit test suite for articulated multibody joint constraints.
 */
class TestJoints {
    public static function run(): Void {
        Assert.suite("Articulated Joint Constraints");

        var pWorld = new PhysicsWorld(new FPVector2(FPNumber.ZERO, FPNumber.fromFloat(-9.81)));

        // Pendulum setup: Static anchor body connected to Dynamic bob via DistanceJoint
        var anchorBody = new RigidBody(BodyStatic, FPVector2.ZERO);
        var bobBody = new RigidBody(BodyDynamic, new FPVector2(FPNumber.fromInt(3), FPNumber.ZERO));
        bobBody.setMass(FPNumber.ONE, FPNumber.ONE);

        var shape = new CircleShape(FPNumber.HALF);
        pWorld.addBody(Entity.make(1, 1), anchorBody, new Collider(shape));
        pWorld.addBody(Entity.make(2, 1), bobBody, new Collider(shape));

        var joint = new DistanceJoint(
            Entity.make(1, 1), Entity.make(2, 1),
            anchorBody, bobBody,
            FPVector2.ZERO, FPVector2.ZERO,
            FPNumber.fromInt(3)
        );
        pWorld.addJoint(joint);

        // Step simulation under gravity for 60 ticks (bob swings as pendulum)
        var dt = FPNumber.ONE / FPNumber.fromInt(60);
        for (i in 0...60) {
            pWorld.step(dt);
        }

        // Verify distance between anchor and bob remains constrained to target length 3.0
        var currentDist = anchorBody.transform.position.distance(bobBody.transform.position);
        Assert.nearEquals(3.0, currentDist.toFloat(), 0.05, "Distance joint must preserve target length during dynamic swinging");
    }
}
