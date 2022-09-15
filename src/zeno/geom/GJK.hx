package zeno.geom;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;

/**
 * Gilbert-Johnson-Keerthi (GJK) convex collision detection algorithm.
 * Evaluates whether two convex shapes intersect in O(1) expected iterations.
 */
class GJK {
    public static var MAX_ITERATIONS: Int = 32;

    /**
     * Determines whether shape A and shape B intersect.
     * If intersection occurs, populates outSimplex with the enclosing triangle.
     */
    public static function testIntersection(
        shapeA: Shape, xfA: FPTransform,
        shapeB: Shape, xfB: FPTransform,
        outSimplex: Simplex
    ): Bool {
        outSimplex.clear();

        // Initial search direction towards shape B center
        var d = xfB.position.sub(xfA.position);
        if (d.lengthSquared() < FPNumber.EPSILON) {
            d = FPVector2.RIGHT;
        }

        // First support point
        var s0 = Minkowski.support(shapeA, xfA, shapeB, xfB, d);
        outSimplex.add(s0);

        // Next direction towards origin
        d = s0.point.negate();

        for (iter in 0...MAX_ITERATIONS) {
            // Find next support point along d
            var s = Minkowski.support(shapeA, xfA, shapeB, xfB, d);

            // If the support point does not cross origin along d, no intersection
            if (s.point.dot(d) < FPNumber.ZERO) {
                return false;
            }

            outSimplex.add(s);

            // Handle simplex evolution
            if (handleSimplex(outSimplex, d)) {
                return true;
            }
        }

        return false;
    }

    private static function handleSimplex(simplex: Simplex, d: FPVector2): Bool {
        var count = simplex.getCount();
        if (count == 2) {
            return handleLine(simplex, d);
        } else if (count == 3) {
            return handleTriangle(simplex, d);
        }
        return false;
    }

    private static function handleLine(simplex: Simplex, d: FPVector2): Bool {
        var b = simplex.get(0);
        var a = simplex.get(1); // Most recently added point

        var ab = b.point.sub(a.point);
        var ao = a.point.negate();

        // Normal perpendicular to ab pointing towards origin
        // (ab x ao) x ab = scalarCross(ab.cross(ao), ab)
        var crossVal = ab.cross(ao);
        var normal = FPVector2.scalarCross(crossVal, ab);

        if (normal.lengthSquared() < FPNumber.EPSILON) {
            normal = ab.perpendicular();
        }

        d.copyFrom(normal);
        return false;
    }

    private static function handleTriangle(simplex: Simplex, d: FPVector2): Bool {
        var c = simplex.get(0);
        var b = simplex.get(1);
        var a = simplex.get(2); // Most recently added point

        var ab = b.point.sub(a.point);
        var ac = c.point.sub(a.point);
        var ao = a.point.negate();

        // Edge normals pointing outward
        var abNormal = FPVector2.scalarCross(ab.cross(ac), ab);
        var acNormal = FPVector2.scalarCross(ac.cross(ab), ac);

        if (abNormal.dot(ao) > FPNumber.ZERO) {
            // Origin is outside edge AB: remove C
            simplex.points.splice(0, 1); // Remove c
            d.copyFrom(abNormal);
            return false;
        }

        if (acNormal.dot(ao) > FPNumber.ZERO) {
            // Origin is outside edge AC: remove B
            simplex.points.splice(1, 1); // Remove b
            d.copyFrom(acNormal);
            return false;
        }

        // Origin is enclosed within triangle ABC: intersection confirmed!
        return true;
    }
}
