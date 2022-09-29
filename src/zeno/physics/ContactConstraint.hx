package zeno.physics;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPMath;

/**
 * Velocity and position constraint equations for a single contact point.
 * Implements Projected Gauss-Seidel / Sequential Impulses with Coulomb friction cone.
 */
class ContactConstraint {
    public var contact: Contact;
    public var bodyA: RigidBody;
    public var bodyB: RigidBody;

    public var normal: FPVector2;
    public var tangent: FPVector2;
    public var rA: FPVector2; // Relative vector from body A center to contact point
    public var rB: FPVector2; // Relative vector from body B center to contact point

    public var normalMass: FPNumber; // Effective mass in normal direction: 1 / (J * M^-1 * J^T)
    public var tangentMass: FPNumber; // Effective mass in tangent direction
    public var velocityBias: FPNumber; // Restitution and Baumgarte penetration resolution bias

    public function new(contact: Contact, bodyA: RigidBody, bodyB: RigidBody) {
        this.contact = contact;
        this.bodyA = bodyA;
        this.bodyB = bodyB;
        this.normal = contact.normal.clone();
        this.tangent = contact.normal.perpendicular();
        this.rA = FPVector2.ZERO.clone();
        this.rB = FPVector2.ZERO.clone();
        this.normalMass = FPNumber.ZERO;
        this.tangentMass = FPNumber.ZERO;
        this.velocityBias = FPNumber.ZERO;
    }

    /**
     * Precomputes Jacobians, effective masses, and velocity bias terms for the time step.
     */
    public function preStep(dt: FPNumber): Void {
        normal.copyFrom(contact.normal);
        tangent = normal.perpendicular();

        rA = contact.point.sub(bodyA.transform.position);
        rB = contact.point.sub(bodyB.transform.position);

        var rnA = rA.cross(normal);
        var rnB = rB.cross(normal);
        var kNormal = bodyA.invMass + bodyB.invMass +
                      (bodyA.invInertia * rnA * rnA) +
                      (bodyB.invInertia * rnB * rnB);
        this.normalMass = (kNormal > FPNumber.ZERO) ? (FPNumber.ONE / kNormal) : FPNumber.ZERO;

        var rtA = rA.cross(tangent);
        var rtB = rB.cross(tangent);
        var kTangent = bodyA.invMass + bodyB.invMass +
                       (bodyA.invInertia * rtA * rtA) +
                       (bodyB.invInertia * rtB * rtB);
        this.tangentMass = (kTangent > FPNumber.ZERO) ? (FPNumber.ONE / kTangent) : FPNumber.ZERO;

        // Relative contact velocity: vB + (wB x rB) - vA - (wA x rA)
        var vA = bodyA.linearVelocity.add(FPVector2.scalarCross(bodyA.angularVelocity, rA));
        var vB = bodyB.linearVelocity.add(FPVector2.scalarCross(bodyB.angularVelocity, rB));
        var relVel = vB.sub(vA);
        var normalVel = relVel.dot(normal);

        // Restitution bias
        var restitutionBias = FPNumber.ZERO;
        var velThreshold = FPNumber.fromFloat(0.5);
        if (normalVel < -velThreshold) {
            restitutionBias = -contact.restitution * normalVel;
        }

        // Baumgarte stabilization penetration bias
        var slop = FPNumber.fromFloat(0.005);
        var beta = FPNumber.fromFloat(0.2);
        var penetrationBias = FPNumber.ZERO;
        if (contact.penetration > slop) {
            penetrationBias = (contact.penetration - slop) * (beta / dt);
        }

        this.velocityBias = restitutionBias + penetrationBias;
    }

    /**
     * Warm starting: injects accumulated normal and tangent impulses from previous frame.
     */
    public function warmStart(): Void {
        var P = normal.mul(contact.normalImpulse).add(tangent.mul(contact.tangentImpulse));

        bodyA.linearVelocity = bodyA.linearVelocity.sub(P.mul(bodyA.invMass));
        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * rA.cross(P));

        bodyB.linearVelocity = bodyB.linearVelocity.add(P.mul(bodyB.invMass));
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * rB.cross(P));
    }

    /**
     * Solves velocity constraints by projecting relative velocity onto normal and tangent impulses.
     */
    public function solveVelocity(): Void {
        // 1. Solve Friction (Tangent impulse)
        var vA = bodyA.linearVelocity.add(FPVector2.scalarCross(bodyA.angularVelocity, rA));
        var vB = bodyB.linearVelocity.add(FPVector2.scalarCross(bodyB.angularVelocity, rB));
        var relVel = vB.sub(vA);

        var tangentVel = relVel.dot(tangent);
        var deltaTangentImpulse = -tangentVel * tangentMass;

        // Clamp friction impulse to Coulomb friction cone: [-mu * Pn, mu * Pn]
        var maxFriction = contact.friction * contact.normalImpulse;
        var oldTangentImpulse = contact.tangentImpulse;
        contact.tangentImpulse = FPMath.clamp(oldTangentImpulse + deltaTangentImpulse, -maxFriction, maxFriction);
        deltaTangentImpulse = contact.tangentImpulse - oldTangentImpulse;

        var Pt = tangent.mul(deltaTangentImpulse);
        bodyA.linearVelocity = bodyA.linearVelocity.sub(Pt.mul(bodyA.invMass));
        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * rA.cross(Pt));
        bodyB.linearVelocity = bodyB.linearVelocity.add(Pt.mul(bodyB.invMass));
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * rB.cross(Pt));

        // 2. Solve Normal impulse
        vA = bodyA.linearVelocity.add(FPVector2.scalarCross(bodyA.angularVelocity, rA));
        vB = bodyB.linearVelocity.add(FPVector2.scalarCross(bodyB.angularVelocity, rB));
        relVel = vB.sub(vA);

        var normalVel = relVel.dot(normal);
        var deltaNormalImpulse = (-(normalVel - velocityBias)) * normalMass;

        // Clamp normal impulse: Pn >= 0 (no pulling impulses)
        var oldNormalImpulse = contact.normalImpulse;
        contact.normalImpulse = FPMath.max(oldNormalImpulse + deltaNormalImpulse, FPNumber.ZERO);
        deltaNormalImpulse = contact.normalImpulse - oldNormalImpulse;

        var Pn = normal.mul(deltaNormalImpulse);
        bodyA.linearVelocity = bodyA.linearVelocity.sub(Pn.mul(bodyA.invMass));
        bodyA.angularVelocity = bodyA.angularVelocity - (bodyA.invInertia * rA.cross(Pn));
        bodyB.linearVelocity = bodyB.linearVelocity.add(Pn.mul(bodyB.invMass));
        bodyB.angularVelocity = bodyB.angularVelocity + (bodyB.invInertia * rB.cross(Pn));
    }
}
