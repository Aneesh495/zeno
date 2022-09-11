package zeno.geom;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.math.FPAABB;
import zeno.math.FPMath;
import zeno.geom.Shape.ShapeType;

/**
 * 2D Capsule collision shape defined by an interior line segment and radius.
 */
class CapsuleShape extends Shape {
    public var radius: FPNumber;
    public var halfHeight: FPNumber;

    public function new(radius: FPNumber, halfHeight: FPNumber, ?density: FPNumber) {
        super(ShapeCapsule, density);
        this.radius = radius > FPNumber.ZERO ? radius : FPNumber.ONE;
        this.halfHeight = halfHeight > FPNumber.ZERO ? halfHeight : FPNumber.ONE;
    }

    override public function getSupport(dir: FPVector2, xf: FPTransform): FPVector2 {
        var localDir = xf.inverseTransformVector(dir);

        // Capsule axis along local Y: from (0, -h) to (0, h)
        var py = localDir.y >= FPNumber.ZERO ? halfHeight : -halfHeight;
        var p0 = new FPVector2(FPNumber.ZERO, py);

        // Add spherical cap offset
        var norm = localDir.normalize();
        var localSupport = p0.add(norm.mul(radius));

        return xf.transformPoint(localSupport);
    }

    override public function computeAABB(xf: FPTransform): FPAABB {
        var p1 = xf.transformPoint(new FPVector2(FPNumber.ZERO, -halfHeight));
        var p2 = xf.transformPoint(new FPVector2(FPNumber.ZERO, halfHeight));

        var minX = FPMath.min(p1.x, p2.x) - radius;
        var minY = FPMath.min(p1.y, p2.y) - radius;
        var maxX = FPMath.max(p1.x, p2.x) + radius;
        var maxY = FPMath.max(p1.y, p2.y) + radius;

        return FPAABB.make(minX, minY, maxX, maxY);
    }

    override public function computeMass(density: FPNumber): {mass: FPNumber, inertia: FPNumber} {
        // Capsule = rectangle (2r * 2h) + 2 half circles (circle of radius r)
        var rectMass = density * (radius * FPNumber.fromInt(2)) * (halfHeight * FPNumber.fromInt(2));
        var circleMass = density * FPNumber.PI * radius * radius;
        var mass = rectMass + circleMass;

        // Inertia approximation
        var h = halfHeight * FPNumber.fromInt(2);
        var r = radius;
        var inertia = mass * ((r * r * FPNumber.HALF) + ((h * h) / FPNumber.fromInt(12)));
        return {mass: mass, inertia: inertia};
    }

    override public function clone(): Shape {
        return new CapsuleShape(radius, halfHeight, density);
    }
}
