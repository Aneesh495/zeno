package zeno.math;

import haxe.Int32;
import haxe.Int64;

/**
 * High-precision Q16.16 fixed-point scalar representation.
 * Implemented as an unboxed 32-bit integer abstract type with operator overloading.
 * Eliminates IEEE-754 floating-point platform discrepancies, providing bit-exact
 * mathematical determinism across all targets and hardware architectures.
 *
 * Fixed-point format:
 * - 1 sign bit
 * - 15 integer bits (range: -32768 to 32767)
 * - 16 fractional bits (precision: 1/65536 = ~0.000015258789)
 */
abstract FPNumber(Int32) from Int32 to Int32 {
    public static inline var SHIFT: Int = 16;
    public static inline var FRACTION_MASK: Int32 = 0x0000FFFF;
    public static inline var INTEGER_MASK: Int32 = ~0x0000FFFF;

    public static var RAW_ZERO(default, never): Int32 = 0;
    public static var RAW_ONE(default, never): Int32 = 1 << SHIFT; // 65536
    public static var RAW_HALF(default, never): Int32 = 1 << (SHIFT - 1); // 32768
    public static var RAW_PI(default, never): Int32 = 205887; // 3.14159265 * 65536
    public static var RAW_TWO_PI(default, never): Int32 = 411775; // 6.2831853 * 65536
    public static var RAW_HALF_PI(default, never): Int32 = 102944; // 1.5707963 * 65536
    public static var RAW_EPSILON(default, never): Int32 = 1; // 1/65536
    public static var RAW_DEG_TO_RAD(default, never): Int32 = 1144; // (PI/180) * 65536
    public static var RAW_RAD_TO_DEG(default, never): Int32 = 3754936; // (180/PI) * 65536
    public static var RAW_MAX(default, never): Int32 = 0x7FFFFFFF;
    public static var RAW_MIN(default, never): Int32 = -0x80000000;

    public static var ZERO(get, never): FPNumber;
    public static var ONE(get, never): FPNumber;
    public static var HALF(get, never): FPNumber;
    public static var PI(get, never): FPNumber;
    public static var TWO_PI(get, never): FPNumber;
    public static var HALF_PI(get, never): FPNumber;
    public static var EPSILON(get, never): FPNumber;
    public static var MAX_VALUE(get, never): FPNumber;
    public static var MIN_VALUE(get, never): FPNumber;

    private static inline function get_ZERO(): FPNumber return new FPNumber(RAW_ZERO);
    private static inline function get_ONE(): FPNumber return new FPNumber(RAW_ONE);
    private static inline function get_HALF(): FPNumber return new FPNumber(RAW_HALF);
    private static inline function get_PI(): FPNumber return new FPNumber(RAW_PI);
    private static inline function get_TWO_PI(): FPNumber return new FPNumber(RAW_TWO_PI);
    private static inline function get_HALF_PI(): FPNumber return new FPNumber(RAW_HALF_PI);
    private static inline function get_EPSILON(): FPNumber return new FPNumber(RAW_EPSILON);
    private static inline function get_MAX_VALUE(): FPNumber return new FPNumber(RAW_MAX);
    private static inline function get_MIN_VALUE(): FPNumber return new FPNumber(RAW_MIN);

    public inline function new(rawValue: Int32) {
        this = rawValue;
    }

    public static inline function fromRaw(raw: Int32): FPNumber {
        return new FPNumber(raw);
    }

    public static inline function fromInt(v: Int): FPNumber {
        return new FPNumber(v << SHIFT);
    }

    public static inline function fromFloat(v: Float): FPNumber {
        return new FPNumber(Std.int(v * 65536.0));
    }

    public inline function toInt(): Int {
        return this >> SHIFT;
    }

    public inline function toFloat(): Float {
        return this / 65536.0;
    }

    public inline function getRaw(): Int32 {
        return this;
    }

    @:op(-A)
    public static inline function negate(a: FPNumber): FPNumber {
        return new FPNumber(-a.getRaw());
    }

    @:op(A + B)
    public static inline function add(a: FPNumber, b: FPNumber): FPNumber {
        return new FPNumber(a.getRaw() + b.getRaw());
    }

    @:op(A + B)
    public static inline function addInt(a: FPNumber, b: Int): FPNumber {
        return new FPNumber(a.getRaw() + (b << SHIFT));
    }

    @:op(A - B)
    public static inline function sub(a: FPNumber, b: FPNumber): FPNumber {
        return new FPNumber(a.getRaw() - b.getRaw());
    }

    @:op(A - B)
    public static inline function subInt(a: FPNumber, b: Int): FPNumber {
        return new FPNumber(a.getRaw() - (b << SHIFT));
    }

    @:op(A * B)
    public static inline function mul(a: FPNumber, b: FPNumber): FPNumber {
        var a64 = Int64.ofInt(a.getRaw());
        var b64 = Int64.ofInt(b.getRaw());
        var prod = Int64.mul(a64, b64);
        var shifted = Int64.shr(prod, SHIFT);
        return new FPNumber(Int64.toInt(shifted));
    }

    @:op(A * B)
    public static inline function mulInt(a: FPNumber, b: Int): FPNumber {
        return new FPNumber(a.getRaw() * b);
    }

    @:op(A / B)
    public static inline function div(a: FPNumber, b: FPNumber): FPNumber {
        var bRaw = b.getRaw();
        if (bRaw == 0) {
            return a.getRaw() >= 0 ? MAX_VALUE : MIN_VALUE;
        }
        var a64 = Int64.ofInt(a.getRaw());
        var shifted = Int64.shl(a64, SHIFT);
        var b64 = Int64.ofInt(bRaw);
        var quotient = Int64.div(shifted, b64);
        return new FPNumber(Int64.toInt(quotient));
    }

    @:op(A / B)
    public static inline function divInt(a: FPNumber, b: Int): FPNumber {
        if (b == 0) return a.getRaw() >= 0 ? MAX_VALUE : MIN_VALUE;
        return new FPNumber(Std.int(a.getRaw() / b));
    }

    @:op(A == B)
    public static inline function eq(a: FPNumber, b: FPNumber): Bool {
        return a.getRaw() == b.getRaw();
    }

    @:op(A != B)
    public static inline function neq(a: FPNumber, b: FPNumber): Bool {
        return a.getRaw() != b.getRaw();
    }

    @:op(A < B)
    public static inline function lt(a: FPNumber, b: FPNumber): Bool {
        return a.getRaw() < b.getRaw();
    }

    @:op(A <= B)
    public static inline function lte(a: FPNumber, b: FPNumber): Bool {
        return a.getRaw() <= b.getRaw();
    }

    @:op(A > B)
    public static inline function gt(a: FPNumber, b: FPNumber): Bool {
        return a.getRaw() > b.getRaw();
    }

    @:op(A >= B)
    public static inline function gte(a: FPNumber, b: FPNumber): Bool {
        return a.getRaw() >= b.getRaw();
    }

    public function toString(): String {
        return Std.string(toFloat());
    }
}
