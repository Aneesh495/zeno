package zeno.physics;

import zeno.Assert;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.geom.CircleShape;
import zeno.physics.PhysicsWorld;
import zeno.physics.RigidBody;
import zeno.physics.Collider;
import zeno.physics.BodyType;
import zeno.ecs.Entity;

/**
 * Unit test suite for rigid body physics, Sequential Impulses, and collision response.
 */
class TestConstraints {
    public static function run(): Void {
        Assert.suite("Physics Constraint Solver & Momentum Conservation");

        // Head-on collision between two identical dynamic spheres with zero gravity and e = 1.0 (elastic)
        var pWorld = new PhysicsWorld(FPVector2.ZERO); // Zero gravity
        var radius = FPNumber.ONE;

        // Ball 1 at (-2, 0) moving right with velocity (+2, 0)
        var b1 = new RigidBody(BodyDynamic, new FPVector2(FPNumber.fromInt(-2), FPNumber.ZERO));
        b1.linearVelocity = new FPVector2(FPNumber.fromInt(2), FPNumber.ZERO);
        b1.setMass(FPNumber.ONE, FPNumber.ONE);
        var col1 = new Collider(new CircleShape(radius), FPNumber.ZERO, FPNumber.ONE); // e = 1.0

        // Ball 2 at (+2, 0) moving left with velocity (-2, 0)
        var b2 = new RigidBody(BodyDynamic, new FPVector2(FPNumber.fromInt(2), FPNumber.ZERO));
        b2.linearVelocity = new FPVector2(FPNumber.fromInt(-2), FPNumber.ZERO);
        b2.setMass(FPNumber.ONE, FPNumber.ONE);
        var col2 = new Collider(new CircleShape(radius), FPNumber.ZERO, FPNumber.ONE); // e = 1.0

        pWorld.addBody(Entity.make(1, 1), b1, col1);
        pWorld.addBody(Entity.make(2, 1), b2, col2);

        // Step simulation across collision point
        var dt = FPNumber.ONE / FPNumber.fromInt(60);
        for (i in 0...60) {
            pWorld.step(dt);
        }

        // Post-collision: velocities should reverse symmetrically (Ball 1 moving left, Ball 2 moving right)
        Assert.isTrue(b1.linearVelocity.x < FPNumber.ZERO, "Ball 1 should bounce leftwards after head-on collision");
        Assert.isTrue(b2.linearVelocity.x > FPNumber.ZERO, "Ball 2 should bounce rightwards after head-on collision");

        // Total linear momentum must be conserved (P_total = m1*v1 + m2*v2 = 0)
        var totalMomentum = (b1.linearVelocity.x * b1.mass) + (b2.linearVelocity.x * b2.mass);
        Assert.nearEquals(0.0, totalMomentum.toFloat(), 0.05, "Total system linear momentum should be conserved");
    }
}
