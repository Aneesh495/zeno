package zeno.physics;

import zeno.math.FPNumber;
import zeno.geom.Shape;

/**
 * Collider component attaching a geometric shape and surface material properties.
 */
class Collider {
    public var shape: Shape;
    public var friction: FPNumber;
    public var restitution: FPNumber;
    public var isSensor: Bool;

    // Bitmask collision filtering
    public var categoryBits: Int;
    public var maskBits: Int;
    public var groupIndex: Int;

    public function new(shape: Shape, ?friction: FPNumber, ?restitution: FPNumber, isSensor: Bool = false) {
        this.shape = shape;
        this.friction = friction != null ? friction : FPNumber.fromFloat(0.3);
        this.restitution = restitution != null ? restitution : FPNumber.fromFloat(0.1);
        this.isSensor = isSensor;

        this.categoryBits = 0x0001;
        this.maskBits = 0xFFFF;
        this.groupIndex = 0;
    }

    /**
     * Determines whether this collider should collide with another collider based on category/mask bits.
     */
    public function shouldCollide(other: Collider): Bool {
        if (groupIndex != 0 && groupIndex == other.groupIndex) {
            return groupIndex > 0;
        }
        var collideA = (maskBits & other.categoryBits) != 0;
        var collideB = (categoryBits & other.maskBits) != 0;
        return collideA && collideB;
    }
}
