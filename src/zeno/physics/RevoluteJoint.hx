package zeno.physics;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPMatrix2x2;
import zeno.ecs.Entity;
import zeno.physics.Joint.JointType;

/**
 * 2D Revolute (pin / hinge) joint constraint.
 * Forces anchor points on body A and body B to coincide in world space
 * while permitting free relative rotation around the anchor pin.
 */
class RevoluteJoint extends Joint {
    public var impulse: FPVector2;

    private var rA: FPVector2;
    private var rB: FPVector2;
    private var massMatrix: FPMatrix2x2;
    private var bias: FPVector2;

    public function new(entA: Entity, entB: Entity, bA: RigidBody, bB: RigidBody, anchorA: FPVector2, anchorB: FPVector2) {
        super(JointRevolute, entA, entB, bA, bB, anchorA, anchorB);
        this.impulse = FPVector2.ZERO.clone();
        this.rA = FPVector2.ZERO.clone();
        this.rB = FPVector2.ZERO.clone();
        this.massMatrix = FPMatrix2x2.identity();
        this.bias = FPVector2.ZERO.clone();
    }

    override public function preStep(dt: FPNumber): Void {
        rA = bodyA.transform.transformVector(localAnchorA);
        rB = bodyB.transform.transformVector(localAnchorB);

        // K = (mA + mB)*I + (iA * rA_skew * rA_skew^T) + (iB * rB_skew * rB_skew^T)
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

        // Position bias
        var pA = bodyA.transform.position.add(rA);
        var pB = bodyB.transform.position.add(rB);
        var C = pB.sub(pA);
        var beta = FPNumber.fromFloat(0.2);
        bias = C.mul(beta / dt);
    }

    override public function warmStart(): Void {
        bodyA.linearVelocity = bodyA.linearVelocity.sub(impulse.mul(bodyA.invMass));
        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * rA.cross(impulse));

        bodyB.linearVelocity = bodyB.linearVelocity.add(impulse.mul(bodyB.invMass));
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * rB.cross(impulse));
    }

    override public function solveVelocity(): Void {
        var vA = bodyA.linearVelocity.add(FPVector2.scalarCross(bodyA.angularVelocity, rA));
        var vB = bodyB.linearVelocity.add(FPVector2.scalarCross(bodyB.angularVelocity, rB));
        var Cdot = vB.sub(vA);

        var deltaImpulse = massMatrix.transform(Cdot.add(bias).negate());
        impulse = impulse.add(deltaImpulse);

        bodyA.linearVelocity = bodyA.linearVelocity.sub(deltaImpulse.mul(bodyA.invMass));
        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * rA.cross(deltaImpulse));

        bodyB.linearVelocity = bodyB.linearVelocity.add(deltaImpulse.mul(bodyB.invMass));
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * rB.cross(deltaImpulse));
    }
}
