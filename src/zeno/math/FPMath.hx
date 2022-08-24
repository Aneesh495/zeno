package zeno.math;

import haxe.Int32;
import haxe.Int64;

/**
 * Deterministic mathematical library operating entirely on fixed-point numbers.
 * Provides CORDIC / Chebyshev trigonometric evaluations, bitwise non-restoring
 * square root, and polynomial approximations guaranteeing identical output
 * regardless of target architecture, CPU endianness, or compiler optimization level.
 */
class FPMath {
    // Precomputed CORDIC angle table for 16 iterations in Q16.16 format
    // angles[i] = atan(2^-i) * 65536
    private static var CORDIC_ANGLES: Array<Int32> = [
        51472, // atan(1)       = 0.785398 rad = 51472
        30386, // atan(1/2)     = 0.463648 rad = 30386
        16055, // atan(1/4)     = 0.244979 rad = 16055
        8150,  // atan(1/8)     = 0.124355 rad = 8150
        4091,  // atan(1/16)    = 0.062419 rad = 4091
        2047,  // atan(1/32)    = 0.031240 rad = 2047
        1024,  // atan(1/64)    = 0.015624 rad = 1024
        512,   // atan(1/128)   = 0.007812 rad = 512
        256,   // atan(1/256)   = 0.003906 rad = 256
        128,   // atan(1/512)   = 0.001953 rad = 128
        64,    // atan(1/1024)  = 0.000977 rad = 64
        32,    // atan(1/2048)  = 0.000488 rad = 32
        16,    // atan(1/4096)  = 0.000244 rad = 16
        8,     // atan(1/8192)  = 0.000122 rad = 8
        4,     // atan(1/16384) = 0.000061 rad = 4
        2      // atan(1/32768) = 0.000031 rad = 2
    ];

    // CORDIC gain product K = ~0.607252935 * 65536 = 39797
    private static inline var CORDIC_K: Int32 = 39797;

    public static inline function abs(v: FPNumber): FPNumber {
        var raw = v.getRaw();
        return FPNumber.fromRaw(raw < 0 ? -raw : raw);
    }

    public static inline function sign(v: FPNumber): FPNumber {
        var raw = v.getRaw();
        if (raw > 0) return FPNumber.ONE;
        if (raw < 0) return -FPNumber.ONE;
        return FPNumber.ZERO;
    }

    public static inline function min(a: FPNumber, b: FPNumber): FPNumber {
        return a.getRaw() < b.getRaw() ? a : b;
    }

    public static inline function max(a: FPNumber, b: FPNumber): FPNumber {
        return a.getRaw() > b.getRaw() ? a : b;
    }

    public static inline function clamp(v: FPNumber, lower: FPNumber, upper: FPNumber): FPNumber {
        var raw = v.getRaw();
        var lRaw = lower.getRaw();
        var uRaw = upper.getRaw();
        if (raw < lRaw) return lower;
        if (raw > uRaw) return upper;
        return v;
    }

    public static inline function floor(v: FPNumber): FPNumber {
        return FPNumber.fromRaw(v.getRaw() & FPNumber.INTEGER_MASK);
    }

    public static inline function ceil(v: FPNumber): FPNumber {
        var raw = v.getRaw();
        var f = raw & FPNumber.INTEGER_MASK;
        return (raw & FPNumber.FRACTION_MASK) != 0 ? FPNumber.fromRaw(f + FPNumber.RAW_ONE) : FPNumber.fromRaw(f);
    }

    public static inline function round(v: FPNumber): FPNumber {
        return floor(v + FPNumber.HALF);
    }

    /**
     * Bitwise integer square root algorithm with fixed-point accuracy.
     * Computes sqrt(v) with full 16-bit fractional precision.
     */
    public static function sqrt(v: FPNumber): FPNumber {
        var raw = v.getRaw();
        if (raw <= 0) return FPNumber.ZERO;

        // Shift left by 16 bits to maintain precision: sqrt(x * 2^16) = sqrt(x) * 2^8
        // Using Int64 to prevent overflow
        var v64 = Int64.shl(Int64.ofInt(raw), FPNumber.SHIFT);

        // Bitwise square root extraction
        var res = Int64.ofInt(0);
        var bit = Int64.shl(Int64.ofInt(1), 62); // Second-to-top bit

        while (Int64.compare(bit, v64) > 0) {
            bit = Int64.shr(bit, 2);
        }

        while (Int64.compare(bit, Int64.ofInt(0)) != 0) {
            var sum = Int64.add(res, bit);
            if (Int64.compare(v64, sum) >= 0) {
                v64 = Int64.sub(v64, sum);
                res = Int64.add(Int64.shr(res, 1), bit);
            } else {
                res = Int64.shr(res, 1);
            }
            bit = Int64.shr(bit, 2);
        }

        return FPNumber.fromRaw(Int64.toInt(res));
    }

    /**
     * Deterministic CORDIC sine and cosine evaluation.
     * @param angleInRadians Angle in fixed-point radians.
     * @return Object containing bit-exact sine and cosine.
     */
    public static function sinCos(angleInRadians: FPNumber): {sin: FPNumber, cos: FPNumber} {
        var rawTheta = angleInRadians.getRaw();

        // Normalize angle to [-PI, PI]
        while (rawTheta > FPNumber.RAW_PI) {
            rawTheta -= FPNumber.RAW_TWO_PI;
        }
        while (rawTheta < -FPNumber.RAW_PI) {
            rawTheta += FPNumber.RAW_TWO_PI;
        }

        // CORDIC operates optimally in [-PI/2, PI/2]
        var signX: Int32 = 1;
        var signY: Int32 = 1;
        if (rawTheta > FPNumber.RAW_HALF_PI) {
            rawTheta = FPNumber.RAW_PI - rawTheta;
            signX = -1;
        } else if (rawTheta < -FPNumber.RAW_HALF_PI) {
            rawTheta = -FPNumber.RAW_PI - rawTheta;
            signX = -1;
        }

        // Initialize CORDIC vector: x = K, y = 0, z = theta
        var x: Int32 = CORDIC_K;
        var y: Int32 = 0;
        var z: Int32 = rawTheta;

        for (i in 0...16) {
            var d: Int32 = (z < 0) ? -1 : 1;
            var nextX = x - (d * (y >> i));
            var nextY = y + (d * (x >> i));
            var nextZ = z - (d * CORDIC_ANGLES[i]);
            x = nextX;
            y = nextY;
            z = nextZ;
        }

        var outCos = FPNumber.fromRaw(x * signX);
        var outSin = FPNumber.fromRaw(y * signY);
        return {sin: outSin, cos: outCos};
    }

    public static inline function sin(angle: FPNumber): FPNumber {
        return sinCos(angle).sin;
    }

    public static inline function cos(angle: FPNumber): FPNumber {
        return sinCos(angle).cos;
    }

    public static inline function tan(angle: FPNumber): FPNumber {
        var sc = sinCos(angle);
        return sc.sin / sc.cos;
    }

    /**
     * Deterministic CORDIC vectoring mode for atan2(y, x).
     * @return Angle in radians in range [-PI, PI].
     */
    public static function atan2(y: FPNumber, x: FPNumber): FPNumber {
        var yRaw = y.getRaw();
        var xRaw = x.getRaw();

        if (xRaw == 0 && yRaw == 0) return FPNumber.ZERO;

        // Handle quadrants
        var baseAngle: Int32 = 0;
        if (xRaw < 0) {
            if (yRaw >= 0) {
                baseAngle = FPNumber.RAW_PI;
                xRaw = -xRaw;
                yRaw = -yRaw;
            } else {
                baseAngle = -FPNumber.RAW_PI;
                xRaw = -xRaw;
                yRaw = -yRaw;
            }
        }

        var currX = xRaw;
        var currY = yRaw;
        var z: Int32 = 0;

        for (i in 0...16) {
            var d: Int32 = (currY > 0) ? 1 : -1;
            var nextX = currX + (d * (currY >> i));
            var nextY = currY - (d * (currX >> i));
            var nextZ = z + (d * CORDIC_ANGLES[i]);
            currX = nextX;
            currY = nextY;
            z = nextZ;
        }

        var finalAngle = baseAngle + z;
        // Normalize back to [-PI, PI]
        while (finalAngle > FPNumber.RAW_PI) finalAngle -= FPNumber.RAW_TWO_PI;
        while (finalAngle < -FPNumber.RAW_PI) finalAngle += FPNumber.RAW_TWO_PI;

        return FPNumber.fromRaw(finalAngle);
    }

    public static inline function asin(v: FPNumber): FPNumber {
        var clamped = clamp(v, -FPNumber.ONE, FPNumber.ONE);
        var oneMinusSqr = FPNumber.ONE - (clamped * clamped);
        return atan2(clamped, sqrt(oneMinusSqr));
    }

    public static inline function acos(v: FPNumber): FPNumber {
        return FPNumber.HALF_PI - asin(v);
    }

    public static inline function lerp(a: FPNumber, b: FPNumber, t: FPNumber): FPNumber {
        return a + (b - a) * clamp(t, FPNumber.ZERO, FPNumber.ONE);
    }

    public static inline function invLerp(a: FPNumber, b: FPNumber, v: FPNumber): FPNumber {
        var diff = b - a;
        if (abs(diff) < FPNumber.EPSILON) return FPNumber.ZERO;
        return clamp((v - a) / diff, FPNumber.ZERO, FPNumber.ONE);
    }

    public static inline function smoothstep(edge0: FPNumber, edge1: FPNumber, x: FPNumber): FPNumber {
        var t = invLerp(edge0, edge1, x);
        // t * t * (3 - 2 * t)
        var three = FPNumber.fromInt(3);
        var two = FPNumber.fromInt(2);
        return t * t * (three - two * t);
    }
}
