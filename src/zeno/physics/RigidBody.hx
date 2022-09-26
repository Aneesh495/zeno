package zeno.physics;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;

/**
 * Rigid body dynamics component.
 * Tracks mass, inertia, velocities, force accumulators, and sleep states.
 */
class RigidBody {
    public var type: BodyType;
    public var transform: FPTransform;
    public var linearVelocity: FPVector2;
    public var angularVelocity: FPNumber;
    public var forceAccumulator: FPVector2;
    public var torqueAccumulator: FPNumber;

    public var mass(default, null): FPNumber;
    public var invMass(default, null): FPNumber;
    public var inertia(default, null): FPNumber;
    public var invInertia(default, null): FPNumber;

    public var linearDamping: FPNumber;
    public var angularDamping: FPNumber;
    public var gravityScale: FPNumber;

    public var isAwake: Bool;
    public var canSleep: Bool;
    public var sleepTime: FPNumber;
    public var isBullet: Bool; // Flag for Continuous Collision Detection (CCD)

    public function new(type: BodyType = BodyDynamic, ?initialPosition: FPVector2, ?initialAngle: FPNumber) {
        this.type = type;
        this.transform = new FPTransform(initialPosition, initialAngle);
        this.linearVelocity = FPVector2.ZERO.clone();
        this.angularVelocity = FPNumber.ZERO;
        this.forceAccumulator = FPVector2.ZERO.clone();
        this.torqueAccumulator = FPNumber.ZERO;

        this.linearDamping = FPNumber.fromFloat(0.01);
        this.angularDamping = FPNumber.fromFloat(0.01);
        this.gravityScale = FPNumber.ONE;

        this.isAwake = true;
        this.canSleep = true;
        this.sleepTime = FPNumber.ZERO;
        this.isBullet = false;

        setMass(FPNumber.ONE, FPNumber.ONE);
    }

    public function setMass(m: FPNumber, i: FPNumber): Void {
        if (type == BodyStatic || type == BodyKinematic) {
            this.mass = FPNumber.ZERO;
            this.invMass = FPNumber.ZERO;
            this.inertia = FPNumber.ZERO;
            this.invInertia = FPNumber.ZERO;
        } else {
            this.mass = m > FPNumber.ZERO ? m : FPNumber.ONE;
            this.invMass = FPNumber.ONE / this.mass;
            this.inertia = i > FPNumber.ZERO ? i : FPNumber.ONE;
            this.invInertia = FPNumber.ONE / this.inertia;
        }
    }

    public inline function applyForce(force: FPVector2): Void {
        if (type != BodyDynamic) return;
        if (!isAwake) wakeUp();
        forceAccumulator = forceAccumulator.add(force);
    }

    public inline function applyForceAtPoint(force: FPVector2, point: FPVector2): Void {
        if (type != BodyDynamic) return;
        if (!isAwake) wakeUp();
        forceAccumulator = forceAccumulator.add(force);
        var r = point.sub(transform.position);
        torqueAccumulator = torqueAccumulator + r.cross(force);
    }

    public inline function applyTorque(torque: FPNumber): Void {
        if (type != BodyDynamic) return;
        if (!isAwake) wakeUp();
        torqueAccumulator = torqueAccumulator + torque;
    }

    public inline function applyLinearImpulse(impulse: FPVector2): Void {
        if (type != BodyDynamic) return;
        if (!isAwake) wakeUp();
        linearVelocity = linearVelocity.add(impulse.mul(invMass));
    }

    public inline function applyLinearImpulseAtPoint(impulse: FPVector2, point: FPVector2): Void {
        if (type != BodyDynamic) return;
        if (!isAwake) wakeUp();
        linearVelocity = linearVelocity.add(impulse.mul(invMass));
        var r = point.sub(transform.position);
        angularVelocity = angularVelocity + (invInertia * r.cross(impulse));
    }

    public inline function applyAngularImpulse(impulse: FPNumber): Void {
        if (type != BodyDynamic) return;
        if (!isAwake) wakeUp();
        angularVelocity = angularVelocity + (invInertia * impulse);
    }

    public inline function wakeUp(): Void {
        isAwake = true;
        sleepTime = FPNumber.ZERO;
    }

    public inline function putToSleep(): Void {
        if (!canSleep || type == BodyStatic) return;
        isAwake = false;
        linearVelocity.set(FPNumber.ZERO, FPNumber.ZERO);
        angularVelocity = FPNumber.ZERO;
        forceAccumulator.set(FPNumber.ZERO, FPNumber.ZERO);
        torqueAccumulator = FPNumber.ZERO;
    }

    public inline function clearAccumulators(): Void {
        forceAccumulator.set(FPNumber.ZERO, FPNumber.ZERO);
        torqueAccumulator = FPNumber.ZERO;
    }
}
