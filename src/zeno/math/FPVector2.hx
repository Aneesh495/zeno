package zeno.math;

/**
 * 2D spatial vector with bit-exact Q16.16 fixed-point components.
 * Serves as the primary spatial coordinate primitive for linear positions,
 * velocities, impulses, forces, and contact normals.
 */
class FPVector2 {
    public var x: FPNumber;
    public var y: FPNumber;

    public function new(x: FPNumber, y: FPNumber) {
        this.x = x;
        this.y = y;
    }

    public static inline function make(x: FPNumber, y: FPNumber): FPVector2 {
        return new FPVector2(x, y);
    }

    public static inline function fromInt(x: Int, y: Int): FPVector2 {
        return new FPVector2(FPNumber.fromInt(x), FPNumber.fromInt(y));
    }

    public static inline function fromFloat(x: Float, y: Float): FPVector2 {
        return new FPVector2(FPNumber.fromFloat(x), FPNumber.fromFloat(y));
    }

    public static var ZERO(get, never): FPVector2;
    public static var ONE(get, never): FPVector2;
    public static var UP(get, never): FPVector2;
    public static var DOWN(get, never): FPVector2;
    public static var LEFT(get, never): FPVector2;
    public static var RIGHT(get, never): FPVector2;

    private static inline function get_ZERO(): FPVector2 return new FPVector2(FPNumber.ZERO, FPNumber.ZERO);
    private static inline function get_ONE(): FPVector2 return new FPVector2(FPNumber.ONE, FPNumber.ONE);
    private static inline function get_UP(): FPVector2 return new FPVector2(FPNumber.ZERO, FPNumber.ONE);
    private static inline function get_DOWN(): FPVector2 return new FPVector2(FPNumber.ZERO, -FPNumber.ONE);
    private static inline function get_LEFT(): FPVector2 return new FPVector2(-FPNumber.ONE, FPNumber.ZERO);
    private static inline function get_RIGHT(): FPVector2 return new FPVector2(FPNumber.ONE, FPNumber.ZERO);

    public inline function set(newX: FPNumber, newY: FPNumber): Void {
        this.x = newX;
        this.y = newY;
    }

    public inline function copyFrom(other: FPVector2): Void {
        this.x = other.x;
        this.y = other.y;
    }

    public inline function clone(): FPVector2 {
        return new FPVector2(this.x, this.y);
    }

    public inline function add(other: FPVector2): FPVector2 {
        return new FPVector2(this.x + other.x, this.y + other.y);
    }

    public inline function sub(other: FPVector2): FPVector2 {
        return new FPVector2(this.x - other.x, this.y - other.y);
    }

    public inline function mul(scalar: FPNumber): FPVector2 {
        return new FPVector2(this.x * scalar, this.y * scalar);
    }

    public inline function div(scalar: FPNumber): FPVector2 {
        return new FPVector2(this.x / scalar, this.y / scalar);
    }

    public inline function negate(): FPVector2 {
        return new FPVector2(-this.x, -this.y);
    }

    public inline function dot(other: FPVector2): FPNumber {
        return (this.x * other.x) + (this.y * other.y);
    }

    /**
     * 2D perpendicular dot product (exterior product or determinant).
     * Yields the z-component of the 3D cross product.
     */
    public inline function cross(other: FPVector2): FPNumber {
        return (this.x * other.y) - (this.y * other.x);
    }

    /**
     * Performs cross product of a 2D vector with a scalar z-component.
     * Equivalent to (v.x, v.y, 0) x (0, 0, s).
     */
    public inline function crossScalar(s: FPNumber): FPVector2 {
        return new FPVector2(this.y * s, -this.x * s);
    }

    /**
     * Performs cross product of a scalar z-component with a 2D vector.
     * Equivalent to (0, 0, s) x (v.x, v.y, 0).
     */
    public static inline function scalarCross(s: FPNumber, v: FPVector2): FPVector2 {
        return new FPVector2(-s * v.y, s * v.x);
    }

    public inline function lengthSquared(): FPNumber {
        return (this.x * this.x) + (this.y * this.y);
    }

    public inline function length(): FPNumber {
        return FPMath.sqrt(lengthSquared());
    }

    public function normalize(): FPVector2 {
        var len = length();
        if (len < FPNumber.EPSILON) {
            return ZERO;
        }
        return div(len);
    }

    public inline function distanceSquared(other: FPVector2): FPNumber {
        var dx = this.x - other.x;
        var dy = this.y - other.y;
        return (dx * dx) + (dy * dy);
    }

    public inline function distance(other: FPVector2): FPNumber {
        return FPMath.sqrt(distanceSquared(other));
    }

    /**
     * Computes the counter-clockwise perpendicular normal vector (-y, x).
     */
    public inline function perpendicular(): FPVector2 {
        return new FPVector2(-this.y, this.x);
    }

    public function rotate(angleInRadians: FPNumber): FPVector2 {
        var sc = FPMath.sinCos(angleInRadians);
        return new FPVector2(
            (this.x * sc.cos) - (this.y * sc.sin),
            (this.x * sc.sin) + (this.y * sc.cos)
        );
    }

    public function reflect(normal: FPVector2): FPVector2 {
        // v - 2 * (v . n) * n
        var d = dot(normal) * FPNumber.fromInt(2);
        return sub(normal.mul(d));
    }

    public static inline function lerp(a: FPVector2, b: FPVector2, t: FPNumber): FPVector2 {
        return new FPVector2(
            FPMath.lerp(a.x, b.x, t),
            FPMath.lerp(a.y, b.y, t)
        );
    }

    public inline function equals(other: FPVector2): Bool {
        if (other == null) return false;
        return this.x == other.x && this.y == other.y;
    }

    public function toString(): String {
        return "(" + this.x.toString() + ", " + this.y.toString() + ")";
    }
}
