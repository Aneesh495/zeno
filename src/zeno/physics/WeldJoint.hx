package zeno.physics;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPMatrix2x2;
import zeno.ecs.Entity;
import zeno.physics.Joint.JointType;

/**
 * 2D Weld joint constraint.
 * Rigidly fuses two rigid bodies together at specified anchor offsets,
 * constraining all 3 degrees of freedom (2 linear, 1 angular).
 */
class WeldJoint extends Joint {
    public var linearImpulse: FPVector2;
    public var angularImpulse: FPNumber;

    private var rA: FPVector2;
    private var rB: FPVector2;
    private var massMatrix: FPMatrix2x2;
    private var angularMass: FPNumber;

    public function new(entA: Entity, entB: Entity, bA: RigidBody, bB: RigidBody, anchorA: FPVector2, anchorB: FPVector2) {
        super(JointWeld, entA, entB, bA, bB, anchorA, anchorB);
        this.linearImpulse = FPVector2.ZERO.clone();
        this.angularImpulse = FPNumber.ZERO;
        this.rA = FPVector2.ZERO.clone();
        this.rB = FPVector2.ZERO.clone();
        this.massMatrix = FPMatrix2x2.identity();
        this.angularMass = FPNumber.ZERO;
    }

    override public function preStep(dt: FPNumber): Void {
        rA = bodyA.transform.transformVector(localAnchorA);
        rB = bodyB.transform.transformVector(localAnchorB);

        var mA = bodyA.invMass;
        var mB = bodyB.invMass;
        var iA = bodyA.invInertia;
        var iB = bodyB.invInertia;

        var k00 = mA + mB + (iA * rA.y * rA.y) + (iB * rB.y * rB.y);
        var k01 = -(iA * rA.x * rA.y) - (iB * rB.x * rB.y);
        var k10 = k01;
        var k11 = mA + mB + (iA * rA.x * rA.x) + (iB * rB.x * rB.x);

        var K = new FPMatrix2x2(k00, k01, k10, k11);
        massMatrix = K.invert();

        var invI = iA + iB;
        angularMass = invI > FPNumber.ZERO ? (FPNumber.ONE / invI) : FPNumber.ZERO;
    }

    override public function warmStart(): Void {
        bodyA.linearVelocity = bodyA.linearVelocity.sub(linearImpulse.mul(bodyA.invMass));
        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * (rA.cross(linearImpulse) + angularImpulse));

        bodyB.linearVelocity = bodyB.linearVelocity.add(linearImpulse.mul(bodyB.invMass));
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * (rB.cross(linearImpulse) + angularImpulse));
    }

    override public function solveVelocity(): Void {
        // 1. Solve angular lock
        var CdotAng = bodyB.angularVelocity - bodyA.angularVelocity;
        var dAngImpulse = -CdotAng * angularMass;
        angularImpulse = angularImpulse + dAngImpulse;

        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * dAngImpulse);
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * dAngImpulse);

        // 2. Solve linear position lock
        var vA = bodyA.linearVelocity.add(FPVector2.scalarCross(bodyA.angularVelocity, rA));
        var vB = bodyB.linearVelocity.add(FPVector2.scalarCross(bodyB.angularVelocity, rB));
        var CdotLin = vB.sub(vA);

        var dLinImpulse = massMatrix.transform(CdotLin.negate());
        linearImpulse = linearImpulse.add(dLinImpulse);

        bodyA.linearVelocity = bodyA.linearVelocity.sub(dLinImpulse.mul(bodyA.invMass));
        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * rA.cross(dLinImpulse));

        bodyB.linearVelocity = bodyB.linearVelocity.add(dLinImpulse.mul(bodyB.invMass));
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * rB.cross(dLinImpulse));
    }
}
