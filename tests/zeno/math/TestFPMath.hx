package zeno.math;

import zeno.Assert;
import zeno.math.FPNumber;
import zeno.math.FPMath;

/**
 * Unit test suite for CORDIC trigonometric and deterministic math operations.
 */
class TestFPMath {
    public static function run(): Void {
        Assert.suite("FPMath CORDIC and Mathematical Functions");

        // Absolute value
        var negFive = FPNumber.fromInt(-5);
        Assert.equals(5, FPMath.abs(negFive).toInt(), "abs(-5) should equal 5");

        // Min / Max / Clamp
        var ten = FPNumber.fromInt(10);
        var twenty = FPNumber.fromInt(20);
        Assert.equals(10, FPMath.min(ten, twenty).toInt(), "min(10, 20) should equal 10");
        Assert.equals(20, FPMath.max(ten, twenty).toInt(), "max(10, 20) should equal 20");
        Assert.equals(15, FPMath.clamp(FPNumber.fromInt(15), ten, twenty).toInt(), "clamp(15, 10, 20) should equal 15");
        Assert.equals(10, FPMath.clamp(FPNumber.fromInt(5), ten, twenty).toInt(), "clamp(5, 10, 20) should equal 10");
        Assert.equals(20, FPMath.clamp(FPNumber.fromInt(25), ten, twenty).toInt(), "clamp(25, 10, 20) should equal 20");

        // Square Root
        var four = FPNumber.fromInt(4);
        Assert.equals(2, FPMath.sqrt(four).toInt(), "sqrt(4) should equal 2");
        var nine = FPNumber.fromInt(9);
        Assert.equals(3, FPMath.sqrt(nine).toInt(), "sqrt(9) should equal 3");
        var sixteen = FPNumber.fromInt(16);
        Assert.equals(4, FPMath.sqrt(sixteen).toInt(), "sqrt(16) should equal 4");
        var hundred = FPNumber.fromInt(100);
        Assert.equals(10, FPMath.sqrt(hundred).toInt(), "sqrt(100) should equal 10");

        // Sqrt edge cases
        Assert.equals(0, FPMath.sqrt(FPNumber.ZERO).toInt(), "sqrt(0) should equal 0");
        Assert.equals(0, FPMath.sqrt(FPNumber.fromInt(-1)).toInt(), "sqrt(-1) should return 0 safely");

        // CORDIC Sine and Cosine
        var zeroRad = FPNumber.ZERO;
        var scZero = FPMath.sinCos(zeroRad);
        Assert.nearEquals(0.0, scZero.sin.toFloat(), 0.005, "sin(0) should be near 0.0");
        Assert.nearEquals(1.0, scZero.cos.toFloat(), 0.005, "cos(0) should be near 1.0");

        var halfPi = FPNumber.HALF_PI;
        var scHalfPi = FPMath.sinCos(halfPi);
        Assert.nearEquals(1.0, scHalfPi.sin.toFloat(), 0.005, "sin(PI/2) should be near 1.0");
        Assert.nearEquals(0.0, scHalfPi.cos.toFloat(), 0.005, "cos(PI/2) should be near 0.0");

        var pi = FPNumber.PI;
        var scPi = FPMath.sinCos(pi);
        Assert.nearEquals(0.0, scPi.sin.toFloat(), 0.005, "sin(PI) should be near 0.0");
        Assert.nearEquals(-1.0, scPi.cos.toFloat(), 0.005, "cos(PI) should be near -1.0");

        // CORDIC Atan2
        var atan0 = FPMath.atan2(FPNumber.ZERO, FPNumber.ONE);
        Assert.nearEquals(0.0, atan0.toFloat(), 0.005, "atan2(0, 1) should be 0.0");

        var atanHalfPi = FPMath.atan2(FPNumber.ONE, FPNumber.ZERO);
        Assert.nearEquals(1.5707, atanHalfPi.toFloat(), 0.005, "atan2(1, 0) should be PI/2 (~1.57)");

        // Lerp
        var lerpMid = FPMath.lerp(ten, twenty, FPNumber.HALF);
        Assert.nearEquals(15.0, lerpMid.toFloat(), 0.001, "lerp(10, 20, 0.5) should equal 15.0");
    }
}
