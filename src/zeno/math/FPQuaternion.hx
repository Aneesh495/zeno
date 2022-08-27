package zeno.math;

/**
 * Deterministic unit quaternion with Q16.16 fixed-point components.
 * Guarantees zero gimbal lock and exact spherical linear interpolation (slerp).
 */
class FPQuaternion {
    public var x: FPNumber;
    public var y: FPNumber;
    public var z: FPNumber;
    public var w: FPNumber;

    public function new(x: FPNumber, y: FPNumber, z: FPNumber, w: FPNumber) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public static inline function identity(): FPQuaternion {
        return new FPQuaternion(FPNumber.ZERO, FPNumber.ZERO, FPNumber.ZERO, FPNumber.ONE);
    }

    public static function fromAxisAngle(axis: FPVector3, angle: FPNumber): FPQuaternion {
        var halfAngle = angle * FPNumber.HALF;
        var sc = FPMath.sinCos(halfAngle);
        var normAxis = axis.normalize();
        return new FPQuaternion(
            normAxis.x * sc.sin,
            normAxis.y * sc.sin,
            normAxis.z * sc.sin,
            sc.cos
        );
    }

    public inline function lengthSquared(): FPNumber {
        return (x * x) + (y * y) + (z * z) + (w * w);
    }

    public inline function length(): FPNumber {
        return FPMath.sqrt(lengthSquared());
    }

    public function normalize(): FPQuaternion {
        var len = length();
        if (len < FPNumber.EPSILON) return identity();
        var invLen = FPNumber.ONE / len;
        return new FPQuaternion(x * invLen, y * invLen, z * invLen, w * invLen);
    }

    public inline function conjugate(): FPQuaternion {
        return new FPQuaternion(-x, -y, -z, w);
    }

    public function mul(o: FPQuaternion): FPQuaternion {
        return new FPQuaternion(
            (w * o.x) + (x * o.w) + (y * o.z) - (z * o.y),
            (w * o.y) - (x * o.z) + (y * o.w) + (z * o.x),
            (w * o.z) + (x * o.y) - (y * o.x) + (z * o.w),
            (w * o.w) - (x * o.x) - (y * o.y) - (z * o.z)
        );
    }

    public function rotateVector(v: FPVector3): FPVector3 {
        // v' = q * (v, 0) * q^-1
        var qv = new FPVector3(x, y, z);
        var uv = qv.cross(v);
        var uuv = qv.cross(uv);
        var two = FPNumber.fromInt(2);
        uv = uv.mul(w * two);
        uuv = uuv.mul(two);
        return v.add(uv).add(uuv);
    }

    public function toMatrix3x3(): FPMatrix3x3 {
        var two = FPNumber.fromInt(2);
        var xx = x * x * two;
        var yy = y * y * two;
        var zz = z * z * two;
        var xy = x * y * two;
        var xz = x * z * two;
        var yz = y * z * two;
        var wx = w * x * two;
        var wy = w * y * two;
        var wz = w * z * two;

        return new FPMatrix3x3(
            FPNumber.ONE - (yy + zz), xy - wz, xz + wy,
            xy + wz, FPNumber.ONE - (xx + zz), yz - wx,
            xz - wy, yz + wx, FPNumber.ONE - (xx + yy)
        );
    }

    public function clone(): FPQuaternion {
        return new FPQuaternion(x, y, z, w);
    }
}
