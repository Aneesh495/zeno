package zeno.geom;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.math.FPAABB;

enum ShapeType {
    ShapeCircle;
    ShapeBox;
    ShapeCapsule;
    ShapePolygon;
}

/**
 * Base abstract convex collision shape.
 * Defines the support mapping interface used by GJK and EPA,
 * AABB generation, and mass/inertia properties.
 */
class Shape {
    public var type(default, null): ShapeType;
    public var density: FPNumber;

    public function new(type: ShapeType, ?density: FPNumber) {
        this.type = type;
        this.density = density != null ? density : FPNumber.ONE;
    }

    /**
     * Evaluates the furthest point on this shape along the given directional vector
     * in world space (support mapping function).
     */
    public function getSupport(dir: FPVector2, xf: FPTransform): FPVector2 {
        return xf.position;
    }

    /**
     * Calculates the world-space bounding box for this shape under the given transform.
     */
    public function computeAABB(xf: FPTransform): FPAABB {
        return new FPAABB(xf.position, xf.position);
    }

    /**
     * Computes the mass and rotational inertia for this shape.
     */
    public function computeMass(density: FPNumber): {mass: FPNumber, inertia: FPNumber} {
        return {mass: FPNumber.ONE, inertia: FPNumber.ONE};
    }

    public function clone(): Shape {
        return new Shape(type, density);
    }
}
