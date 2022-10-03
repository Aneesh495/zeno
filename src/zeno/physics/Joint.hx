package zeno.physics;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.ecs.Entity;

enum JointType {
    JointDistance;
    JointRevolute;
    JointPrismatic;
    JointWeld;
}

/**
 * Base abstract articulated joint constraint connecting two rigid bodies.
 */
class Joint {
    public var type(default, null): JointType;
    public var entityA: Entity;
    public var entityB: Entity;
    public var bodyA: RigidBody;
    public var bodyB: RigidBody;
    public var localAnchorA: FPVector2;
    public var localAnchorB: FPVector2;

    public function new(type: JointType, entA: Entity, entB: Entity, bA: RigidBody, bB: RigidBody, anchorA: FPVector2, anchorB: FPVector2) {
        this.type = type;
        this.entityA = entA;
        this.entityB = entB;
        this.bodyA = bA;
        this.bodyB = bB;
        this.localAnchorA = anchorA.clone();
        this.localAnchorB = anchorB.clone();
    }

    public function preStep(dt: FPNumber): Void {}
    public function warmStart(): Void {}
    public function solveVelocity(): Void {}
    public function solvePosition(): Bool return true;
}
