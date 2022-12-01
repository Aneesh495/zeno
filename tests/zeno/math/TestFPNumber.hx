package zeno.math;

import zeno.Assert;
import zeno.math.FPNumber;

/**
 * Unit test suite for Q16.16 fixed-point scalar arithmetic.
 */
class TestFPNumber {
    public static function run(): Void {
        Assert.suite("FPNumber Fixed-Point Arithmetic");

        // Basic constants and conversions
        var zero = FPNumber.ZERO;
        var one = FPNumber.ONE;
        var half = FPNumber.HALF;

        Assert.equals(0, zero.toInt(), "FPNumber.ZERO toInt should be 0");
        Assert.equals(1, one.toInt(), "FPNumber.ONE toInt should be 1");
        Assert.nearEquals(0.5, half.toFloat(), 0.0001, "FPNumber.HALF toFloat should be 0.5");

        // Addition and Subtraction
        var two = one + one;
        Assert.equals(2, two.toInt(), "1 + 1 should equal 2");
        var three = two + 1;
        Assert.equals(3, three.toInt(), "2 + 1 should equal 3");
        var diff = three - one;
        Assert.equals(2, diff.toInt(), "3 - 1 should equal 2");

        // Multiplication
        var six = two * three;
        Assert.equals(6, six.toInt(), "2 * 3 should equal 6");

        var halfTimesFour = half * FPNumber.fromInt(4);
        Assert.equals(2, halfTimesFour.toInt(), "0.5 * 4 should equal 2");

        // Division
        var divRes = six / two;
        Assert.equals(3, divRes.toInt(), "6 / 2 should equal 3");

        var divZero = one / zero;
        Assert.isTrue(divZero == FPNumber.MAX_VALUE, "Division by zero should saturate to MAX_VALUE");

        // Comparisons
        Assert.isTrue(two > one, "2 > 1 should be true");
        Assert.isTrue(one < two, "1 < 2 should be true");
        Assert.isTrue(two >= two, "2 >= 2 should be true");
        Assert.isTrue(one <= two, "1 <= 2 should be true");
        Assert.isTrue(two == FPNumber.fromInt(2), "2 == 2 should be true");
        Assert.isTrue(one != two, "1 != 2 should be true");

        // Regressing and verifying large number multiplication saturation
        // (Bug: multiplying large fixed-point scalars without saturation threw an uncaught Overflow exception in eval)
        testLargeMultiplicationSaturation();
    }

    private static function testLargeMultiplicationSaturation(): Void {
        var bigA = FPNumber.fromInt(1000);
        var bigB = FPNumber.fromInt(1000);
        // In Q16.16: 1000 * 1000 = 1,000,000, which exceeds 32,767 max value.
        // It must saturate to MAX_VALUE rather than throwing an uncaught overflow exception!
        var prod = bigA * bigB;
        Assert.isTrue(prod == FPNumber.MAX_VALUE, "Multiplying large numbers exceeding Q16.16 range must saturate to MAX_VALUE without throwing exception");

        var negBigA = FPNumber.fromInt(-1000);
        var negProd = negBigA * bigB;
        Assert.isTrue(negProd == FPNumber.MIN_VALUE, "Multiplying negative large numbers must saturate to MIN_VALUE without throwing exception");
    }
}
