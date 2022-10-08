package zeno.physics;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.ecs.Entity;
import zeno.physics.Joint.JointType;

/**
 * 2D Prismatic (slider) joint constraint.
 * Allows relative translation along a single prescribed axis while
 * preventing perpendicular displacement and relative angular rotation.
 */
class PrismaticJoint extends Joint {
    public var localAxisA: FPVector2;
    public var impulse: FPVector2; // (perpendicular impulse, angular impulse)

    private var rA: FPVector2;
    private var rB: FPVector2;
    private var perpAxis: FPVector2;
    private var massK1: FPNumber;
    private var massK2: FPNumber;

    public function new(entA: Entity, entB: Entity, bA: RigidBody, bB: RigidBody, anchorA: FPVector2, anchorB: FPVector2, axisA: FPVector2) {
        super(JointPrismatic, entA, entB, bA, bB, anchorA, anchorB);
        this.localAxisA = axisA.normalize();
        this.impulse = FPVector2.ZERO.clone();
        this.rA = FPVector2.ZERO.clone();
        this.rB = FPVector2.ZERO.clone();
        this.perpAxis = FPVector2.ZERO.clone();
        this.massK1 = FPNumber.ZERO;
        this.massK2 = FPNumber.ZERO;
    }

    override public function preStep(dt: FPNumber): Void {
        rA = bodyA.transform.transformVector(localAnchorA);
        rB = bodyB.transform.transformVector(localAnchorB);
        var axis = bodyA.transform.transformVector(localAxisA);
        perpAxis = axis.perpendicular();

        var crAp = rA.cross(perpAxis);
        var crBp = rB.cross(perpAxis);
        var k1 = bodyA.invMass + bodyB.invMass + (bodyA.invInertia * crAp * crAp) + (bodyB.invInertia * crBp * crBp);
        massK1 = k1 > FPNumber.ZERO ? (FPNumber.ONE / k1) : FPNumber.ZERO;

        var k2 = bodyA.invInertia + bodyB.invInertia;
        massK2 = k2 > FPNumber.ZERO ? (FPNumber.ONE / k2) : FPNumber.ZERO;
    }

    override public function solveVelocity(): Void {
        // 1. Solve linear perpendicular constraint
        var vA = bodyA.linearVelocity.add(FPVector2.scalarCross(bodyA.angularVelocity, rA));
        var vB = bodyB.linearVelocity.add(FPVector2.scalarCross(bodyB.angularVelocity, rB));
        var Cdot1 = perpAxis.dot(vB.sub(vA));

        var dImpulse1 = -Cdot1 * massK1;
        impulse.x = impulse.x + dImpulse1;

        var P1 = perpAxis.mul(dImpulse1);
        bodyA.linearVelocity = bodyA.linearVelocity.sub(P1.mul(bodyA.invMass));
        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * rA.cross(P1));
        bodyB.linearVelocity = bodyB.linearVelocity.add(P1.mul(bodyB.invMass));
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * rB.cross(P1));

        // 2. Solve angular lock constraint
        var Cdot2 = bodyB.angularVelocity - bodyA.angularVelocity;
        var dImpulse2 = -Cdot2 * massK2;
        impulse.y = impulse.y + dImpulse2;

        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * dImpulse2);
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * dImpulse2);
    }
}
