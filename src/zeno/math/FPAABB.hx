package zeno.math;

/**
 * Axis-Aligned Bounding Box (AABB) using fixed-point coordinates.
 * Core primitive for spatial bounding, broadphase acceleration trees (BVH),
 * and fast rejection culling.
 */
class FPAABB {
    public var lowerBound: FPVector2;
    public var upperBound: FPVector2;

    public function new(?lower: FPVector2, ?upper: FPVector2) {
        this.lowerBound = lower != null ? lower : FPVector2.ZERO;
        this.upperBound = upper != null ? upper : FPVector2.ZERO;
    }

    public static inline function make(minX: FPNumber, minY: FPNumber, maxX: FPNumber, maxY: FPNumber): FPAABB {
        return new FPAABB(new FPVector2(minX, minY), new FPVector2(maxX, maxY));
    }

    public inline function getCenter(): FPVector2 {
        return (lowerBound.add(upperBound)).mul(FPNumber.HALF);
    }

    public inline function getExtents(): FPVector2 {
        return (upperBound.sub(lowerBound)).mul(FPNumber.HALF);
    }

    public inline function getPerimeter(): FPNumber {
        var dx = upperBound.x - lowerBound.x;
        var dy = upperBound.y - lowerBound.y;
        var two = FPNumber.fromInt(2);
        return two * (dx + dy);
    }

    public inline function getArea(): FPNumber {
        var dx = upperBound.x - lowerBound.x;
        var dy = upperBound.y - lowerBound.y;
        return dx * dy;
    }

    public inline function containsPoint(p: FPVector2): Bool {
        return p.x >= lowerBound.x && p.x <= upperBound.x &&
               p.y >= lowerBound.y && p.y <= upperBound.y;
    }

    public inline function containsAABB(other: FPAABB): Bool {
        return lowerBound.x <= other.lowerBound.x &&
               lowerBound.y <= other.lowerBound.y &&
               other.upperBound.x <= upperBound.x &&
               other.upperBound.y <= upperBound.y;
    }

    public inline function intersects(other: FPAABB): Bool {
        var d1x = other.lowerBound.x - upperBound.x;
        var d1y = other.lowerBound.y - upperBound.y;
        var d2x = lowerBound.x - other.upperBound.x;
        var d2y = lowerBound.y - other.upperBound.y;

        if (d1x > FPNumber.ZERO || d1y > FPNumber.ZERO) return false;
        if (d2x > FPNumber.ZERO || d2y > FPNumber.ZERO) return false;
        return true;
    }

    public function combine(a: FPAABB, b: FPAABB): Void {
        lowerBound.x = FPMath.min(a.lowerBound.x, b.lowerBound.x);
        lowerBound.y = FPMath.min(a.lowerBound.y, b.lowerBound.y);
        upperBound.x = FPMath.max(a.upperBound.x, b.upperBound.x);
        upperBound.y = FPMath.max(a.upperBound.y, b.upperBound.y);
    }

    public function expand(margin: FPNumber): Void {
        lowerBound.x = lowerBound.x - margin;
        lowerBound.y = lowerBound.y - margin;
        upperBound.x = upperBound.x + margin;
        upperBound.y = upperBound.y + margin;
    }

    /**
     * Ray-AABB intersection test using the slab method.
     * @param origin Starting point of ray.
     * @param dir Direction vector of ray.
     * @param maxFraction Maximum normalized ray distance.
     * @return True if ray penetrates this bounding box within maxFraction.
     */
    public function raycast(origin: FPVector2, dir: FPVector2, maxFraction: FPNumber): Bool {
        var tmin = -FPNumber.MAX_VALUE;
        var tmax = FPNumber.MAX_VALUE;

        // X axis slab
        if (FPMath.abs(dir.x) < FPNumber.EPSILON) {
            if (origin.x < lowerBound.x || origin.x > upperBound.x) return false;
        } else {
            var invD = FPNumber.ONE / dir.x;
            var t1 = (lowerBound.x - origin.x) * invD;
            var t2 = (upperBound.x - origin.x) * invD;
            var smin = FPMath.min(t1, t2);
            var smax = FPMath.max(t1, t2);
            tmin = FPMath.max(tmin, smin);
            tmax = FPMath.min(tmax, smax);
            if (tmin > tmax) return false;
        }

        // Y axis slab
        if (FPMath.abs(dir.y) < FPNumber.EPSILON) {
            if (origin.y < lowerBound.y || origin.y > upperBound.y) return false;
        } else {
            var invD = FPNumber.ONE / dir.y;
            var t1 = (lowerBound.y - origin.y) * invD;
            var t2 = (upperBound.y - origin.y) * invD;
            var smin = FPMath.min(t1, t2);
            var smax = FPMath.max(t1, t2);
            tmin = FPMath.max(tmin, smin);
            tmax = FPMath.min(tmax, smax);
            if (tmin > tmax) return false;
        }

        return tmax >= FPNumber.ZERO && tmin <= maxFraction;
    }

    public function clone(): FPAABB {
        return new FPAABB(lowerBound.clone(), upperBound.clone());
    }
}
