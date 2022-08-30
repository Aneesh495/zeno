package zeno.math;

/**
 * 2D spatial rigid transform combining position and orientation.
 * Encapsulates coordinate space conversions between local body space
 * and global simulation world space.
 */
class FPTransform {
    public var position: FPVector2;
    public var rotation: FPMatrix2x2;
    public var angle: FPNumber;

    public function new(?position: FPVector2, ?angle: FPNumber) {
        this.position = position != null ? position : FPVector2.ZERO;
        this.angle = angle != null ? angle : FPNumber.ZERO;
        this.rotation = FPMatrix2x2.fromAngle(this.angle);
    }

    public static inline function identity(): FPTransform {
        return new FPTransform(FPVector2.ZERO, FPNumber.ZERO);
    }

    public function set(pos: FPVector2, ang: FPNumber): Void {
        this.position.copyFrom(pos);
        this.angle = ang;
        this.rotation = FPMatrix2x2.fromAngle(ang);
    }

    public function setAngle(ang: FPNumber): Void {
        this.angle = ang;
        this.rotation = FPMatrix2x2.fromAngle(ang);
    }

    /**
     * Transforms a point from local body space to world space: T * v + p.
     */
    public inline function transformPoint(localPoint: FPVector2): FPVector2 {
        var rotated = rotation.transform(localPoint);
        return rotated.add(position);
    }

    /**
     * Transforms a directional vector (e.g. normal or axis) from local to world space: T * v.
     */
    public inline function transformVector(localVector: FPVector2): FPVector2 {
        return rotation.transform(localVector);
    }

    /**
     * Transforms a point from world space back to local body space: T^T * (v - p).
     */
    public inline function inverseTransformPoint(worldPoint: FPVector2): FPVector2 {
        var relative = worldPoint.sub(position);
        return rotation.transformTranspose(relative);
    }

    /**
     * Transforms a directional vector from world space back to local body space: T^T * v.
     */
    public inline function inverseTransformVector(worldVector: FPVector2): FPVector2 {
        return rotation.transformTranspose(worldVector);
    }

    public function clone(): FPTransform {
        return new FPTransform(this.position.clone(), this.angle);
    }
}
