package zeno.geom;

import zeno.Assert;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.geom.CircleShape;
import zeno.geom.BoxShape;
import zeno.geom.Simplex;
import zeno.geom.GJK;

/**
 * Unit test suite for Gilbert-Johnson-Keerthi (GJK) convex collision detection.
 */
class TestGJK {
    public static function run(): Void {
        Assert.suite("GJK Convex Collision Detection");

        var simplex = new Simplex();

        // 1. Overlapping Boxes
        var boxA = BoxShape.make(FPNumber.fromInt(2), FPNumber.fromInt(2));
        var boxB = BoxShape.make(FPNumber.fromInt(2), FPNumber.fromInt(2));
        var xfA = new FPTransform(FPVector2.ZERO, FPNumber.ZERO);
        var xfB = new FPTransform(new FPVector2(FPNumber.fromFloat(1.5), FPNumber.ZERO), FPNumber.ZERO);

        var hitBoxes = GJK.testIntersection(boxA, xfA, boxB, xfB, simplex);
        Assert.isTrue(hitBoxes, "Overlapping boxes must return true in GJK");

        // 2. Disjoint Boxes
        var xfDisjoint = new FPTransform(new FPVector2(FPNumber.fromInt(5), FPNumber.ZERO), FPNumber.ZERO);
        var missBoxes = GJK.testIntersection(boxA, xfA, boxB, xfDisjoint, simplex);
        Assert.isFalse(missBoxes, "Separated boxes must return false in GJK");

        // 3. Overlapping Circles
        var circleA = new CircleShape(FPNumber.ONE);
        var circleB = new CircleShape(FPNumber.ONE);
        var xfCircleA = new FPTransform(FPVector2.ZERO, FPNumber.ZERO);
        var xfCircleB = new FPTransform(new FPVector2(FPNumber.fromFloat(1.2), FPNumber.ZERO), FPNumber.ZERO);

        var hitCircles = GJK.testIntersection(circleA, xfCircleA, circleB, xfCircleB, simplex);
        Assert.isTrue(hitCircles, "Overlapping circles must return true in GJK");

        // 4. Disjoint Circles
        var xfCircleFar = new FPTransform(new FPVector2(FPNumber.fromInt(3), FPNumber.ZERO), FPNumber.ZERO);
        var missCircles = GJK.testIntersection(circleA, xfCircleA, circleB, xfCircleFar, simplex);
        Assert.isFalse(missCircles, "Separated circles must return false in GJK");

        // 5. Box vs Circle Overlap
        var hitBoxCircle = GJK.testIntersection(boxA, xfA, circleB, xfCircleB, simplex);
        Assert.isTrue(hitBoxCircle, "Overlapping box and circle must return true in GJK");
    }
}
