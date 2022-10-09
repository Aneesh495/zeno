package zeno.physics;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPMath;

/**
 * Isolated simulation island representing a connected subgraph of bodies,
 * contacts, and joints that can be solved and put to sleep as an atomic unit.
 */
class Island {
    public var bodies: Array<RigidBody>;
    public var contacts: Array<ContactConstraint>;
    public var joints: Array<Joint>;

    public function new() {
        this.bodies = new Array<RigidBody>();
        this.contacts = new Array<ContactConstraint>();
        this.joints = new Array<Joint>();
    }

    public inline function addBody(body: RigidBody): Void {
        bodies.push(body);
    }

    public inline function addContact(c: ContactConstraint): Void {
        contacts.push(c);
    }

    public inline function addJoint(j: Joint): Void {
        joints.push(j);
    }

    /**
     * Solves velocity constraints across the island for the specified iteration count.
     */
    public function solve(velocityIterations: Int, dt: FPNumber): Void {
        // 1. Pre-step and warm start
        for (c in contacts) {
            c.preStep(dt);
            c.warmStart();
        }
        for (j in joints) {
            j.preStep(dt);
            j.warmStart();
        }

        // 2. Velocity constraint solver iterations
        for (iter in 0...velocityIterations) {
            for (j in joints) {
                j.solveVelocity();
            }
            for (c in contacts) {
                c.solveVelocity();
            }
        }

        // 3. Integrate body positions: p += v * dt, theta += omega * dt
        for (b in bodies) {
            if (b.type != BodyDynamic) continue;

            b.transform.position = b.transform.position.add(b.linearVelocity.mul(dt));
            b.transform.setAngle(b.transform.angle + (b.angularVelocity * dt));

            // Apply damping: v *= (1 / (1 + damping * dt))
            var linFactor = FPNumber.ONE / (FPNumber.ONE + (b.linearDamping * dt));
            var angFactor = FPNumber.ONE / (FPNumber.ONE + (b.angularDamping * dt));
            b.linearVelocity = b.linearVelocity.mul(linFactor);
            b.angularVelocity = b.angularVelocity * angFactor;
        }
    }

    /**
     * Evaluates whether the island is quiescent and should be transitioned to sleeping.
     */
    public function evaluateSleep(dt: FPNumber): Void {
        var minSleepTime = FPNumber.MAX_VALUE;
        var linTolSq = FPNumber.fromFloat(0.0004); // (0.02)^2
        var angTol = FPNumber.fromFloat(0.04);

        for (b in bodies) {
            if (b.type == BodyStatic) continue;

            if (!b.canSleep ||
                b.linearVelocity.lengthSquared() > linTolSq ||
                FPMath.abs(b.angularVelocity) > angTol) {
                b.sleepTime = FPNumber.ZERO;
                minSleepTime = FPNumber.ZERO;
            } else {
                b.sleepTime = b.sleepTime + dt;
                minSleepTime = FPMath.min(minSleepTime, b.sleepTime);
            }
        }

        // If all bodies in island exceeded sleep threshold (0.5s), put whole island to sleep
        var sleepThreshold = FPNumber.fromFloat(0.5);
        if (minSleepTime >= sleepThreshold) {
            for (b in bodies) {
                b.putToSleep();
            }
        }
    }

    public function clear(): Void {
        while (bodies.length > 0) bodies.pop();
        while (contacts.length > 0) contacts.pop();
        while (joints.length > 0) joints.pop();
    }
}
