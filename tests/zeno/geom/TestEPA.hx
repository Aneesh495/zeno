package zeno.geom;

import zeno.Assert;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.geom.CircleShape;
import zeno.geom.BoxShape;
import zeno.geom.Simplex;
import zeno.geom.GJK;
import zeno.geom.EPA;
import zeno.geom.EPA.ContactManifold;

/**
 * Unit test suite for Expanding Polytope Algorithm (EPA) contact manifold extraction.
 */
class TestEPA {
    public static function run(): Void {
        Assert.suite("EPA Contact Manifold & Penetration Depth");

        var simplex = new Simplex();
        var manifold = new ContactManifold();

        // Two boxes overlapping horizontally by 0.5 units:
        // BoxA at (0, 0), halfExtents = (1, 1), spans [-1, 1]
        // BoxB at (1.5, 0), halfExtents = (1, 1), spans [0.5, 2.5]
        // Overlap = 1.0 - 0.5 = 0.5 units along X axis
        var boxA = BoxShape.make(FPNumber.fromInt(2), FPNumber.fromInt(2));
        var boxB = BoxShape.make(FPNumber.fromInt(2), FPNumber.fromInt(2));
        var xfA = new FPTransform(FPVector2.ZERO, FPNumber.ZERO);
        var xfB = new FPTransform(new FPVector2(FPNumber.fromFloat(1.5), FPNumber.ZERO), FPNumber.ZERO);

        var hit = GJK.testIntersection(boxA, xfA, boxB, xfB, simplex);
        Assert.isTrue(hit, "GJK should confirm intersection prior to EPA");

        var manifoldFound = EPA.computeManifold(boxA, xfA, boxB, xfB, simplex, manifold);
        Assert.isTrue(manifoldFound, "EPA should successfully extract contact manifold");
        Assert.isTrue(manifold.isValid, "Manifold should be marked valid");
        Assert.nearEquals(0.5, manifold.penetration.toFloat(), 0.05, "EPA penetration depth should be approximately 0.5");
        Assert.nearEquals(1.0, Math.abs(manifold.normal.x.toFloat()), 0.05, "EPA contact normal should be aligned with X-axis");
    }
}
