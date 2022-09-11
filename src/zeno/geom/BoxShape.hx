package zeno.geom;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.math.FPAABB;
import zeno.math.FPMath;
import zeno.geom.Shape.ShapeType;

/**
 * 2D Oriented Bounding Box (OBB) shape defined by half-width and half-height.
 */
class BoxShape extends Shape {
    public var halfExtents: FPVector2;

    public function new(halfWidth: FPNumber, halfHeight: FPNumber, ?density: FPNumber) {
        super(ShapeBox, density);
        this.halfExtents = new FPVector2(
            halfWidth > FPNumber.ZERO ? halfWidth : FPNumber.ONE,
            halfHeight > FPNumber.ZERO ? halfHeight : FPNumber.ONE
        );
    }

    public static inline function make(width: FPNumber, height: FPNumber, ?density: FPNumber): BoxShape {
        return new BoxShape(width * FPNumber.HALF, height * FPNumber.HALF, density);
    }

    override public function getSupport(dir: FPVector2, xf: FPTransform): FPVector2 {
        // Transform direction into local body coordinates: T^T * d
        var localDir = xf.inverseTransformVector(dir);

        // Support point in local coordinates: sign(d.x) * w, sign(d.y) * h
        var sx = localDir.x >= FPNumber.ZERO ? halfExtents.x : -halfExtents.x;
        var sy = localDir.y >= FPNumber.ZERO ? halfExtents.y : -halfExtents.y;
        var localSupport = new FPVector2(sx, sy);

        // Transform local support point back to world space: T * p
        return xf.transformPoint(localSupport);
    }

    override public function computeAABB(xf: FPTransform): FPAABB {
        // Rotated AABB extents: |R| * halfExtents
        var rot = xf.rotation;
        var ex = (FPMath.abs(rot.m00) * halfExtents.x) + (FPMath.abs(rot.m01) * halfExtents.y);
        var ey = (FPMath.abs(rot.m10) * halfExtents.x) + (FPMath.abs(rot.m11) * halfExtents.y);
        var extents = new FPVector2(ex, ey);

        return new FPAABB(xf.position.sub(extents), xf.position.add(extents));
    }

    override public function computeMass(density: FPNumber): {mass: FPNumber, inertia: FPNumber} {
        // width = 2 * hx, height = 2 * hy
        var w = halfExtents.x * FPNumber.fromInt(2);
        var h = halfExtents.y * FPNumber.fromInt(2);
        var mass = density * w * h;
        // inertia = (1/12) * mass * (w^2 + h^2)
        var oneTwelfth = FPNumber.ONE / FPNumber.fromInt(12);
        var inertia = mass * ((w * w) + (h * h)) * oneTwelfth;
        return {mass: mass, inertia: inertia};
    }

    override public function clone(): Shape {
        return new BoxShape(halfExtents.x, halfExtents.y, density);
    }
}
