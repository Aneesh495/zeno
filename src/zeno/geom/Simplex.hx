package zeno.geom;

import zeno.math.FPNumber;
import zeno.math.FPVector2;

/**
 * Support point record preserving mapping from source shapes.
 */
class SupportPoint {
    public var point: FPVector2; // Minkowski difference point (pA - pB)
    public var pointA: FPVector2; // Original point on shape A
    public var pointB: FPVector2; // Original point on shape B

    public function new(p: FPVector2, pA: FPVector2, pB: FPVector2) {
        this.point = p;
        this.pointA = pA;
        this.pointB = pB;
    }

    public function clone(): SupportPoint {
        return new SupportPoint(point.clone(), pointA.clone(), pointB.clone());
    }
}

/**
 * Simplex representation used by the GJK algorithm.
 * Maintains up to 3 support points in 2D space.
 */
class Simplex {
    public var points: Array<SupportPoint>;

    public function new() {
        this.points = new Array<SupportPoint>();
    }

    public inline function getCount(): Int {
        return points.length;
    }

    public inline function add(pt: SupportPoint): Void {
        points.push(pt);
    }

    public inline function get(index: Int): SupportPoint {
        return points[index];
    }

    public inline function clear(): Void {
        while (points.length > 0) points.pop();
    }
}
