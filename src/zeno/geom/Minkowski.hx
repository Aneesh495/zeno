package zeno.geom;

import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.geom.Simplex.SupportPoint;

/**
 * Evaluates Minkowski difference support mappings between arbitrary convex shapes.
 * Minkowski difference: A - B = { a - b | a in A, b in B }
 * Support mapping property: S_{A - B}(d) = S_A(d) - S_B(-d)
 */
class Minkowski {
    public static function support(shapeA: Shape, xfA: FPTransform, shapeB: Shape, xfB: FPTransform, dir: FPVector2): SupportPoint {
        var pA = shapeA.getSupport(dir, xfA);
        var pB = shapeB.getSupport(dir.negate(), xfB);
        var diff = pA.sub(pB);
        return new SupportPoint(diff, pA, pB);
    }
}
