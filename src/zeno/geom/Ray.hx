package zeno.geom;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.ecs.Entity;

/**
 * Spatial raycast query definition.
 */
class Ray {
    public var origin: FPVector2;
    public var direction: FPVector2;
    public var maxDistance: FPNumber;

    public function new(origin: FPVector2, direction: FPVector2, maxDistance: FPNumber) {
        this.origin = origin;
        this.direction = direction.normalize();
        this.maxDistance = maxDistance;
    }

    public inline function getPoint(fraction: FPNumber): FPVector2 {
        return origin.add(direction.mul(maxDistance * fraction));
    }
}

/**
 * Result data structure populated upon successful ray intersection.
 */
class RaycastHit {
    public var entity: Entity;
    public var point: FPVector2;
    public var normal: FPVector2;
    public var distance: FPNumber;
    public var fraction: FPNumber;

    public function new() {
        this.entity = Entity.NONE;
        this.point = FPVector2.ZERO;
        this.normal = FPVector2.ZERO;
        this.distance = FPNumber.ZERO;
        this.fraction = FPNumber.ONE;
    }

    public function set(ent: Entity, pt: FPVector2, norm: FPVector2, dist: FPNumber, frac: FPNumber): Void {
        this.entity = ent;
        this.point = pt;
        this.normal = norm;
        this.distance = dist;
        this.fraction = frac;
    }
}
