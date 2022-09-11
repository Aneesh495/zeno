package zeno.geom;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.math.FPAABB;
import zeno.math.FPMath;
import zeno.geom.Shape.ShapeType;

/**
 * 2D Circle collision shape defined by radius.
 */
class CircleShape extends Shape {
    public var radius: FPNumber;

    public function new(radius: FPNumber, ?density: FPNumber) {
        super(ShapeCircle, density);
        this.radius = radius > FPNumber.ZERO ? radius : FPNumber.ONE;
    }

    override public function getSupport(dir: FPVector2, xf: FPTransform): FPVector2 {
        var norm = dir.normalize();
        var offset = norm.mul(radius);
        return xf.position.add(offset);
    }

    override public function computeAABB(xf: FPTransform): FPAABB {
        var rVec = new FPVector2(radius, radius);
        return new FPAABB(xf.position.sub(rVec), xf.position.add(rVec));
    }

    override public function computeMass(density: FPNumber): {mass: FPNumber, inertia: FPNumber} {
        // mass = density * PI * r^2
        var mass = density * FPNumber.PI * radius * radius;
        // inertia = 0.5 * mass * r^2
        var inertia = mass * radius * radius * FPNumber.HALF;
        return {mass: mass, inertia: inertia};
    }

    override public function clone(): Shape {
        return new CircleShape(radius, density);
    }
}
