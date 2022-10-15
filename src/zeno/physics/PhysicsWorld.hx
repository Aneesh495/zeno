package zeno.physics;

import haxe.ds.StringMap;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.ecs.Entity;
import zeno.geom.Shape;
import zeno.geom.CircleShape;
import zeno.geom.BoxShape;
import zeno.geom.GJK;
import zeno.geom.EPA;
import zeno.geom.EPA.ContactManifold;
import zeno.geom.SAT;
import zeno.geom.Simplex;
import zeno.spatial.Broadphase;

class BodyRecord {
    public var entity: Entity;
    public var body: RigidBody;
    public var collider: Collider;

    public function new(e: Entity, b: RigidBody, c: Collider) {
        this.entity = e;
        this.body = b;
        this.collider = c;
    }
}

/**
 * Deterministic 2D Rigid Body Physics Engine.
 * Integrates broadphase BVH spatial acceleration, GJK/EPA/SAT narrowphase,
 * Sequential Impulses constraint solver, articulated joints, and continuous collision detection.
 */
class PhysicsWorld {
    public var gravity: FPVector2;
    public var velocityIterations: Int;
    public var positionIterations: Int;

    private var broadphase: Broadphase;
    private var islandManager: IslandManager;
    private var bodies: Array<BodyRecord>;
    private var contacts: StringMap<Contact>;
    private var joints: Array<Joint>;

    public function new(?gravity: FPVector2) {
        this.gravity = gravity != null ? gravity : new FPVector2(FPNumber.ZERO, FPNumber.fromFloat(-9.81));
        this.velocityIterations = 8;
        this.positionIterations = 3;
        this.broadphase = new Broadphase();
        this.islandManager = new IslandManager();
        this.bodies = new Array<BodyRecord>();
        this.contacts = new StringMap<Contact>();
        this.joints = new Array<Joint>();
    }

    public inline function getBroadphase(): Broadphase return broadphase;
    public inline function getBodyCount(): Int return bodies.length;
    public inline function getJointCount(): Int return joints.length;

    /**
     * Registers a rigid body and collider pair into the physics world.
     */
    public function addBody(entity: Entity, body: RigidBody, collider: Collider): Void {
        var rec = new BodyRecord(entity, body, collider);
        bodies.push(rec);

        var aabb = collider.shape.computeAABB(body.transform);
        broadphase.createProxy(entity, aabb);
    }

    /**
     * Removes an entity from the physics world and cleans up associated contacts and joints.
     */
    public function removeBody(entity: Entity): Void {
        broadphase.destroyProxy(entity);

        // Remove from bodies list
        var idx = -1;
        for (i in 0...bodies.length) {
            if (bodies[i].entity == entity) {
                idx = i;
                break;
            }
        }
        if (idx >= 0) bodies.splice(idx, 1);

        // Remove associated joints
        var j = joints.length - 1;
        while (j >= 0) {
            if (joints[j].entityA == entity || joints[j].entityB == entity) {
                joints.splice(j, 1);
            }
            j--;
        }
    }

    public function addJoint(joint: Joint): Void {
        joints.push(joint);
    }

    public function removeJoint(joint: Joint): Void {
        var idx = joints.indexOf(joint);
        if (idx >= 0) joints.splice(idx, 1);
    }

    /**
     * Advances the physics simulation by a deterministic fixed time step dt.
     */
    public function step(dt: FPNumber): Void {
        // 1. Integrate forces and apply gravity
        for (rec in bodies) {
            var b = rec.body;
            if (b.type != BodyDynamic || !b.isAwake) continue;

            // v += (g * gravityScale + force * invMass) * dt
            var totalForce = gravity.mul(b.gravityScale * b.mass).add(b.forceAccumulator);
            b.linearVelocity = b.linearVelocity.add(totalForce.mul(b.invMass * dt));
            b.angularVelocity = b.angularVelocity + (b.torqueAccumulator * b.invInertia * dt);

            b.clearAccumulators();
        }

        // 2. Continuous Collision Detection (CCD) for high-speed bullet bodies
        for (rec in bodies) {
            var b = rec.body;
            if (b.type != BodyDynamic || !b.isBullet || !b.isAwake) continue;

            for (other in bodies) {
                if (rec == other || other.body.type == BodyDynamic) continue;
                var toi = ContinuousCollision.computeTimeOfImpact(
                    rec.collider.shape, b.transform, b.linearVelocity,
                    other.collider.shape, other.body.transform, other.body.linearVelocity,
                    dt
                );

                if (toi < FPNumber.ONE) {
                    // Advance body to exact TOI point to prevent tunneling
                    b.transform.position = b.transform.position.add(b.linearVelocity.mul(toi * dt));
                    b.linearVelocity.set(FPNumber.ZERO, FPNumber.ZERO);
                    break;
                }
            }
        }

        // 3. Update broadphase proxies with displacement prediction
        for (rec in bodies) {
            var b = rec.body;
            var aabb = rec.collider.shape.computeAABB(b.transform);
            var disp = b.linearVelocity.mul(dt);
            broadphase.moveProxy(rec.entity, aabb, disp);
        }

        // 4. Broadphase pair discovery and narrowphase collision dispatch
        var activeConstraints = new Array<ContactConstraint>();
        var manifold = new ContactManifold();
        var simplex = new Simplex();

        broadphase.computePairs(function(entA: Entity, entB: Entity): Void {
            var recA = getRecord(entA);
            var recB = getRecord(entB);
            if (recA == null || recB == null) return;

            // Static vs Static check
            if (recA.body.type == BodyStatic && recB.body.type == BodyStatic) return;

            // Collision filtering
            if (!recA.collider.shouldCollide(recB.collider)) return;

            // Narrowphase collision check
            var hasCollision = false;
            var shapeA = recA.collider.shape;
            var shapeB = recB.collider.shape;
            var xfA = recA.body.transform;
            var xfB = recB.body.transform;

            if (shapeA.type == ShapeCircle && shapeB.type == ShapeCircle) {
                hasCollision = SAT.testCircleCircle(cast shapeA, xfA, cast shapeB, xfB, manifold);
            } else if (shapeA.type == ShapeBox && shapeB.type == ShapeCircle) {
                hasCollision = SAT.testBoxCircle(cast shapeA, xfA, cast shapeB, xfB, manifold);
            } else if (shapeA.type == ShapeCircle && shapeB.type == ShapeBox) {
                hasCollision = SAT.testBoxCircle(cast shapeB, xfB, cast shapeA, xfA, manifold);
                if (hasCollision) {
                    manifold.normal = manifold.normal.negate();
                }
            } else {
                // Generic GJK + EPA
                if (GJK.testIntersection(shapeA, xfA, shapeB, xfB, simplex)) {
                    hasCollision = EPA.computeManifold(shapeA, xfA, shapeB, xfB, simplex, manifold);
                }
            }

            var pairKey = entA.getRaw() + "_" + entB.getRaw();
            var contact = contacts.get(pairKey);

            if (hasCollision && manifold.isValid) {
                if (contact == null) {
                    contact = new Contact(entA, entB);
                    contacts.set(pairKey, contact);
                }

                // Mixed surface material properties: friction = sqrt(fA * fB), restitution = max(rA, rB)
                var frictionCoeff = zeno.math.FPMath.sqrt(recA.collider.friction * recB.collider.friction);
                var restitutionCoeff = zeno.math.FPMath.max(recA.collider.restitution, recB.collider.restitution);

                contact.update(manifold, frictionCoeff, restitutionCoeff);
                contact.isSensor = recA.collider.isSensor || recB.collider.isSensor;

                if (!contact.isSensor) {
                    var constraint = new ContactConstraint(contact, recA.body, recB.body);
                    activeConstraints.push(constraint);
                }
            } else {
                if (contact != null) {
                    contact.isTouching = false;
                    contact.resetImpulses();
                }
            }
        });

        // 5. Build and solve simulation islands
        var rigidBodies = new Array<RigidBody>();
        for (r in bodies) rigidBodies.push(r.body);

        islandManager.solveAll(rigidBodies, activeConstraints, joints, velocityIterations, dt);
    }

    private function getRecord(entity: Entity): BodyRecord {
        for (rec in bodies) {
            if (rec.entity == entity) return rec;
        }
        return null;
    }

    public function clear(): Void {
        broadphase.clear();
        islandManager.clear();
        contacts = new StringMap<Contact>();
        while (bodies.length > 0) bodies.pop();
        while (joints.length > 0) joints.pop();
    }
}
