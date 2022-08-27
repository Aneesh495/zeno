package zeno.math;

/**
 * 3x3 fixed-point matrix representation.
 * Supports 3D spatial transformations, rotational inertia tensors,
 * and 3-degree-of-freedom constraint solving.
 */
class FPMatrix3x3 {
    public var m00: FPNumber; public var m01: FPNumber; public var m02: FPNumber;
    public var m10: FPNumber; public var m11: FPNumber; public var m12: FPNumber;
    public var m20: FPNumber; public var m21: FPNumber; public var m22: FPNumber;

    public function new(
        m00: FPNumber, m01: FPNumber, m02: FPNumber,
        m10: FPNumber, m11: FPNumber, m12: FPNumber,
        m20: FPNumber, m21: FPNumber, m22: FPNumber
    ) {
        this.m00 = m00; this.m01 = m01; this.m02 = m02;
        this.m10 = m10; this.m11 = m11; this.m12 = m12;
        this.m20 = m20; this.m21 = m21; this.m22 = m22;
    }

    public static inline function identity(): FPMatrix3x3 {
        return new FPMatrix3x3(
            FPNumber.ONE, FPNumber.ZERO, FPNumber.ZERO,
            FPNumber.ZERO, FPNumber.ONE, FPNumber.ZERO,
            FPNumber.ZERO, FPNumber.ZERO, FPNumber.ONE
        );
    }

    public inline function transform(v: FPVector3): FPVector3 {
        return new FPVector3(
            (m00 * v.x) + (m01 * v.y) + (m02 * v.z),
            (m10 * v.x) + (m11 * v.y) + (m12 * v.z),
            (m20 * v.x) + (m21 * v.y) + (m22 * v.z)
        );
    }

    public function mul(o: FPMatrix3x3): FPMatrix3x3 {
        return new FPMatrix3x3(
            (m00 * o.m00) + (m01 * o.m10) + (m02 * o.m20),
            (m00 * o.m01) + (m01 * o.m11) + (m02 * o.m21),
            (m00 * o.m02) + (m01 * o.m12) + (m02 * o.m22),

            (m10 * o.m00) + (m11 * o.m10) + (m12 * o.m20),
            (m10 * o.m01) + (m11 * o.m11) + (m12 * o.m21),
            (m10 * o.m02) + (m11 * o.m12) + (m12 * o.m22),

            (m20 * o.m00) + (m21 * o.m10) + (m22 * o.m20),
            (m20 * o.m01) + (m21 * o.m11) + (m22 * o.m21),
            (m20 * o.m02) + (m21 * o.m12) + (m22 * o.m22)
        );
    }

    public inline function transpose(): FPMatrix3x3 {
        return new FPMatrix3x3(
            m00, m10, m20,
            m01, m11, m21,
            m02, m12, m22
        );
    }

    public function determinant(): FPNumber {
        var t0 = m00 * ((m11 * m22) - (m12 * m21));
        var t1 = m01 * ((m10 * m22) - (m12 * m20));
        var t2 = m02 * ((m10 * m21) - (m11 * m20));
        return t0 - t1 + t2;
    }

    public function clone(): FPMatrix3x3 {
        return new FPMatrix3x3(m00, m01, m02, m10, m11, m12, m20, m21, m22);
    }
}
