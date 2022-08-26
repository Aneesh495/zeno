package zeno.math;

/**
 * 3D spatial vector with bit-exact Q16.16 fixed-point components.
 * Supports 3D linear and angular kinematics, torque integration,
 * and 3D vector algebra.
 */
class FPVector3 {
    public var x: FPNumber;
    public var y: FPNumber;
    public var z: FPNumber;

    public function new(x: FPNumber, y: FPNumber, z: FPNumber) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public static inline function make(x: FPNumber, y: FPNumber, z: FPNumber): FPVector3 {
        return new FPVector3(x, y, z);
    }

    public static inline function fromInt(x: Int, y: Int, z: Int): FPVector3 {
        return new FPVector3(FPNumber.fromInt(x), FPNumber.fromInt(y), FPNumber.fromInt(z));
    }

    public static inline function fromFloat(x: Float, y: Float, z: Float): FPVector3 {
        return new FPVector3(FPNumber.fromFloat(x), FPNumber.fromFloat(y), FPNumber.fromFloat(z));
    }

    public static var ZERO(get, never): FPVector3;
    public static var ONE(get, never): FPVector3;
    public static var UP(get, never): FPVector3;
    public static var FORWARD(get, never): FPVector3;
    public static var RIGHT(get, never): FPVector3;

    private static inline function get_ZERO(): FPVector3 return new FPVector3(FPNumber.ZERO, FPNumber.ZERO, FPNumber.ZERO);
    private static inline function get_ONE(): FPVector3 return new FPVector3(FPNumber.ONE, FPNumber.ONE, FPNumber.ONE);
    private static inline function get_UP(): FPVector3 return new FPVector3(FPNumber.ZERO, FPNumber.ONE, FPNumber.ZERO);
    private static inline function get_FORWARD(): FPVector3 return new FPVector3(FPNumber.ZERO, FPNumber.ZERO, FPNumber.ONE);
    private static inline function get_RIGHT(): FPVector3 return new FPVector3(FPNumber.ONE, FPNumber.ZERO, FPNumber.ZERO);

    public inline function set(newX: FPNumber, newY: FPNumber, newZ: FPNumber): Void {
        this.x = newX;
        this.y = newY;
        this.z = newZ;
    }

    public inline function copyFrom(other: FPVector3): Void {
        this.x = other.x;
        this.y = other.y;
        this.z = other.z;
    }

    public inline function clone(): FPVector3 {
        return new FPVector3(this.x, this.y, this.z);
    }

    public inline function add(other: FPVector3): FPVector3 {
        return new FPVector3(this.x + other.x, this.y + other.y, this.z + other.z);
    }

    public inline function sub(other: FPVector3): FPVector3 {
        return new FPVector3(this.x - other.x, this.y - other.y, this.z - other.z);
    }

    public inline function mul(scalar: FPNumber): FPVector3 {
        return new FPVector3(this.x * scalar, this.y * scalar, this.z * scalar);
    }

    public inline function div(scalar: FPNumber): FPVector3 {
        return new FPVector3(this.x / scalar, this.y / scalar, this.z / scalar);
    }

    public inline function negate(): FPVector3 {
        return new FPVector3(-this.x, -this.y, -this.z);
    }

    public inline function dot(other: FPVector3): FPNumber {
        return (this.x * other.x) + (this.y * other.y) + (this.z * other.z);
    }

    public inline function cross(other: FPVector3): FPVector3 {
        return new FPVector3(
            (this.y * other.z) - (this.z * other.y),
            (this.z * other.x) - (this.x * other.z),
            (this.x * other.y) - (this.y * other.x)
        );
    }

    public inline function lengthSquared(): FPNumber {
        return (this.x * this.x) + (this.y * this.y) + (this.z * this.z);
    }

    public inline function length(): FPNumber {
        return FPMath.sqrt(lengthSquared());
    }

    public function normalize(): FPVector3 {
        var len = length();
        if (len < FPNumber.EPSILON) return ZERO;
        return div(len);
    }

    public inline function distanceSquared(other: FPVector3): FPNumber {
        var dx = this.x - other.x;
        var dy = this.y - other.y;
        var dz = this.z - other.z;
        return (dx * dx) + (dy * dy) + (dz * dz);
    }

    public inline function distance(other: FPVector3): FPNumber {
        return FPMath.sqrt(distanceSquared(other));
    }

    public static inline function lerp(a: FPVector3, b: FPVector3, t: FPNumber): FPVector3 {
        return new FPVector3(
            FPMath.lerp(a.x, b.x, t),
            FPMath.lerp(a.y, b.y, t),
            FPMath.lerp(a.z, b.z, t)
        );
    }

    public inline function equals(other: FPVector3): Bool {
        if (other == null) return false;
        return this.x == other.x && this.y == other.y && this.z == other.z;
    }

    public function toString(): String {
        return "(" + this.x.toString() + ", " + this.y.toString() + ", " + this.z.toString() + ")";
    }
}
