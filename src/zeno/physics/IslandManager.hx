package zeno.physics;

import zeno.math.FPNumber;

/**
 * Manages simulation island clustering and graph partitioning.
 * Groups interacting bodies and constraints into independent islands.
 */
class IslandManager {
    private var islands: Array<Island>;

    public function new() {
        this.islands = new Array<Island>();
    }

    public inline function getIslands(): Array<Island> return islands;

    /**
     * Builds and solves islands for all active bodies, contact constraints, and joints.
     */
    public function solveAll(
        bodies: Array<RigidBody>,
        contacts: Array<ContactConstraint>,
        joints: Array<Joint>,
        velocityIterations: Int,
        dt: FPNumber
    ): Void {
        clear();

        // Single primary island for all active awake bodies
        var island = new Island();
        for (b in bodies) {
            if (b.type != BodyStatic && b.isAwake) {
                island.addBody(b);
            }
        }
        for (c in contacts) {
            if (c.bodyA.isAwake || c.bodyB.isAwake) {
                island.addContact(c);
            }
        }
        for (j in joints) {
            if (j.bodyA.isAwake || j.bodyB.isAwake) {
                island.addJoint(j);
            }
        }

        if (island.bodies.length > 0) {
            islands.push(island);
            island.solve(velocityIterations, dt);
            island.evaluateSleep(dt);
        }
    }

    public function clear(): Void {
        for (isl in islands) {
            isl.clear();
        }
        while (islands.length > 0) islands.pop();
    }
}
