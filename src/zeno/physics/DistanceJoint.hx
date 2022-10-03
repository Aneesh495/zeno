package zeno.physics;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.ecs.Entity;
import zeno.physics.Joint.JointType;

/**
 * Fixed or compliant distance constraint between two rigid bodies.
 */
class DistanceJoint extends Joint {
    public var targetDistance: FPNumber;
    public var impulse: FPNumber;

    private var u: FPVector2; // Unit vector along constraint axis
    private var rA: FPVector2;
    private var rB: FPVector2;
    private var mass: FPNumber;
    private var bias: FPNumber;

    public function new(entA: Entity, entB: Entity, bA: RigidBody, bB: RigidBody, anchorA: FPVector2, anchorB: FPVector2, ?length: FPNumber) {
        super(JointDistance, entA, entB, bA, bB, anchorA, anchorB);
        this.impulse = FPNumber.ZERO;
        this.u = FPVector2.ZERO.clone();
        this.rA = FPVector2.ZERO.clone();
        this.rB = FPVector2.ZERO.clone();

        if (length != null) {
            this.targetDistance = length;
        } else {
            var pA = bA.transform.transformPoint(anchorA);
            var pB = bB.transform.transformPoint(anchorB);
            this.targetDistance = pA.distance(pB);
        }
    }

    override public function preStep(dt: FPNumber): Void {
        rA = bodyA.transform.transformVector(localAnchorA);
        rB = bodyB.transform.transformVector(localAnchorB);

        var pA = bodyA.transform.position.add(rA);
        var pB = bodyB.transform.position.add(rB);
        var d = pB.sub(pA);

        var currentLength = d.length();
        if (currentLength > FPNumber.EPSILON) {
            u = d.div(currentLength);
        } else {
            u = FPVector2.ZERO.clone();
        }

        var crAu = rA.cross(u);
        var crBu = rB.cross(u);
        var invMass = bodyA.invMass + bodyB.invMass + (bodyA.invInertia * crAu * crAu) + (bodyB.invInertia * crBu * crBu);
        this.mass = invMass > FPNumber.ZERO ? (FPNumber.ONE / invMass) : FPNumber.ZERO;

        // Position bias
        var C = currentLength - targetDistance;
        var beta = FPNumber.fromFloat(0.1);
        this.bias = (beta / dt) * C;
    }

    override public function warmStart(): Void {
        var P = u.mul(impulse);
        bodyA.linearVelocity = bodyA.linearVelocity.sub(P.mul(bodyA.invMass));
        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * rA.cross(P));

        bodyB.linearVelocity = bodyB.linearVelocity.add(P.mul(bodyB.invMass));
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * rB.cross(P));
    }

    override public function solveVelocity(): Void {
        var vA = bodyA.linearVelocity.add(FPVector2.scalarCross(bodyA.angularVelocity, rA));
        var vB = bodyB.linearVelocity.add(FPVector2.scalarCross(bodyB.angularVelocity, rB));
        var Cdot = u.dot(vB.sub(vA));

        var deltaImpulse = -mass * (Cdot + bias);
        impulse = impulse + deltaImpulse;

        var P = u.mul(deltaImpulse);
        bodyA.linearVelocity = bodyA.linearVelocity.sub(P.mul(bodyA.invMass));
        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * rA.cross(P));

        bodyB.linearVelocity = bodyB.linearVelocity.add(P.mul(bodyB.invMass));
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * rB.cross(P));
    }
}
