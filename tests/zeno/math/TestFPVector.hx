package zeno.math;

import zeno.Assert;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPVector3;

/**
 * Unit test suite for 2D and 3D fixed-point vector mathematics.
 */
class TestFPVector {
    public static function run(): Void {
        Assert.suite("FPVector2 and FPVector3 Spatial Vectors");

        // 2D Vector operations
        var v1 = new FPVector2(FPNumber.fromInt(3), FPNumber.fromInt(4));
        var v2 = new FPVector2(FPNumber.fromInt(1), FPNumber.fromInt(2));

        var sum = v1.add(v2);
        Assert.equals(4, sum.x.toInt(), "v1.x + v2.x should equal 4");
        Assert.equals(6, sum.y.toInt(), "v1.y + v2.y should equal 6");

        var diff = v1.sub(v2);
        Assert.equals(2, diff.x.toInt(), "v1.x - v2.x should equal 2");
        Assert.equals(2, diff.y.toInt(), "v1.y - v2.y should equal 2");

        // Length and Normalization
        Assert.equals(25, v1.lengthSquared().toInt(), "lengthSquared of (3, 4) should equal 25");
        Assert.equals(5, v1.length().toInt(), "length of (3, 4) should equal 5");

        var norm = v1.normalize();
        Assert.nearEquals(0.6, norm.x.toFloat(), 0.005, "normalized x of (3, 4) should be 0.6");
        Assert.nearEquals(0.8, norm.y.toFloat(), 0.005, "normalized y of (3, 4) should be 0.8");
        Assert.nearEquals(1.0, norm.length().toFloat(), 0.005, "normalized length should be 1.0");

        // Dot and Cross products
        var dot = v1.dot(v2); // 3*1 + 4*2 = 11
        Assert.equals(11, dot.toInt(), "dot product of (3, 4) and (1, 2) should equal 11");

        var cross = v1.cross(v2); // 3*2 - 4*1 = 2
        Assert.equals(2, cross.toInt(), "2D cross product should equal 2");

        // Distance
        var dist = v1.distance(new FPVector2(FPNumber.fromInt(3), FPNumber.fromInt(1)));
        Assert.equals(3, dist.toInt(), "distance between (3, 4) and (3, 1) should equal 3");

        // 3D Vector operations
        var v3a = new FPVector3(FPNumber.ONE, FPNumber.ZERO, FPNumber.ZERO);
        var v3b = new FPVector3(FPNumber.ZERO, FPNumber.ONE, FPNumber.ZERO);
        var cross3 = v3a.cross(v3b);
        Assert.equals(0, cross3.x.toInt(), "cross(X, Y).x should equal 0");
        Assert.equals(0, cross3.y.toInt(), "cross(X, Y).y should equal 0");
        Assert.equals(1, cross3.z.toInt(), "cross(X, Y).z should equal 1 (Z-axis)");
    }
}
