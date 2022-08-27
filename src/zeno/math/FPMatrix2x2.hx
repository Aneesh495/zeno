package zeno.math;

/**
 * 2x2 fixed-point transformation matrix.
 * Represents 2D rotations, scaling, and 2x2 linear constraint equations.
 */
class FPMatrix2x2 {
    public var m00: FPNumber;
    public var m01: FPNumber;
    public var m10: FPNumber;
    public var m11: FPNumber;

    public function new(m00: FPNumber, m01: FPNumber, m10: FPNumber, m11: FPNumber) {
        this.m00 = m00;
        this.m01 = m01;
        this.m10 = m10;
        this.m11 = m11;
    }

    public static inline function identity(): FPMatrix2x2 {
        return new FPMatrix2x2(FPNumber.ONE, FPNumber.ZERO, FPNumber.ZERO, FPNumber.ONE);
    }

    public static function fromAngle(angleInRadians: FPNumber): FPMatrix2x2 {
        var sc = FPMath.sinCos(angleInRadians);
        return new FPMatrix2x2(sc.cos, -sc.sin, sc.sin, sc.cos);
    }

    public inline function transform(v: FPVector2): FPVector2 {
        return new FPVector2(
            (m00 * v.x) + (m01 * v.y),
            (m10 * v.x) + (m11 * v.y)
        );
    }

    public inline function transformTranspose(v: FPVector2): FPVector2 {
        return new FPVector2(
            (m00 * v.x) + (m10 * v.y),
            (m01 * v.x) + (m11 * v.y)
        );
    }

    public inline function mul(other: FPMatrix2x2): FPMatrix2x2 {
        return new FPMatrix2x2(
            (m00 * other.m00) + (m01 * other.m10),
            (m00 * other.m01) + (m01 * other.m11),
            (m10 * other.m00) + (m11 * other.m10),
            (m10 * other.m01) + (m11 * other.m11)
        );
    }

    public inline function transpose(): FPMatrix2x2 {
        return new FPMatrix2x2(m00, m10, m01, m11);
    }

    public inline function determinant(): FPNumber {
        return (m00 * m11) - (m01 * m10);
    }

    public function invert(): FPMatrix2x2 {
        var det = determinant();
        if (FPMath.abs(det) < FPNumber.EPSILON) {
            return identity();
        }
        var invDet = FPNumber.ONE / det;
        return new FPMatrix2x2(
            m11 * invDet,
            -m01 * invDet,
            -m10 * invDet,
            m00 * invDet
        );
    }

    public function clone(): FPMatrix2x2 {
        return new FPMatrix2x2(m00, m01, m10, m11);
    }
}
