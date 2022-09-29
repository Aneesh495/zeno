package zeno.physics;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.ecs.Entity;
import zeno.geom.EPA.ContactManifold;

/**
 * Representation of an active physical contact pair between two entities.
 * Caches accumulated normal and tangent impulses across frames for warm starting.
 */
class Contact {
    public var entityA: Entity;
    public var entityB: Entity;
    public var normal: FPVector2; // Normal pointing from A to B
    public var point: FPVector2; // Contact point in world space
    public var penetration: FPNumber;

    public var normalImpulse: FPNumber;
    public var tangentImpulse: FPNumber;
    public var friction: FPNumber;
    public var restitution: FPNumber;

    public var isTouching: Bool;
    public var isSensor: Bool;

    public function new(entA: Entity, entB: Entity) {
        this.entityA = entA;
        this.entityB = entB;
        this.normal = FPVector2.ZERO.clone();
        this.point = FPVector2.ZERO.clone();
        this.penetration = FPNumber.ZERO;
        this.normalImpulse = FPNumber.ZERO;
        this.tangentImpulse = FPNumber.ZERO;
        this.friction = FPNumber.fromFloat(0.3);
        this.restitution = FPNumber.ZERO;
        this.isTouching = false;
        this.isSensor = false;
    }

    public function update(manifold: ContactManifold, frictionCoeff: FPNumber, restitutionCoeff: FPNumber): Void {
        this.normal.copyFrom(manifold.normal);
        this.point.copyFrom(manifold.point);
        this.penetration = manifold.penetration;
        this.friction = frictionCoeff;
        this.restitution = restitutionCoeff;
        this.isTouching = manifold.isValid;
    }

    public function resetImpulses(): Void {
        this.normalImpulse = FPNumber.ZERO;
        this.tangentImpulse = FPNumber.ZERO;
    }
}
