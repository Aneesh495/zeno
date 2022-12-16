package zeno;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPRandom;
import zeno.ecs.World;
import zeno.ecs.Entity;
import zeno.ecs.ComponentType;
import zeno.geom.Shape;
import zeno.geom.CircleShape;
import zeno.geom.BoxShape;
import zeno.physics.PhysicsWorld;
import zeno.physics.RigidBody;
import zeno.physics.Collider;
import zeno.physics.BodyType;
import zeno.physics.Joint;
import zeno.rollback.RollbackManager;
import zeno.rollback.Snapshot;
import zeno.event.EventBus;

/**
 * Zeno Simulation Engine.
 * Top-level facade coordinating the archetype ECS world, deterministic physics engine,
 * speculative rollback manager, and event bus into a unified simulation runtime.
 */
@:expose("Zeno")
class Zeno {
    public var world(default, null): World;
    public var physics(default, null): PhysicsWorld;
    public var rollback(default, null): RollbackManager;
    public var eventBus(default, null): EventBus;
    public var prng(default, null): FPRandom;
    public var fixedDeltaTime(default, null): FPNumber;

    public function new(seed: Int = 42, players: Int = 2, tickRateHz: Int = 60) {
        this.fixedDeltaTime = FPNumber.ONE / FPNumber.fromInt(tickRateHz);
        this.prng = new FPRandom(seed);
        this.world = new World(1024);
        this.physics = new PhysicsWorld();
        this.eventBus = new EventBus();

        this.rollback = new RollbackManager(
            players,
            64,
            captureSnapshot,
            restoreSnapshot,
            stepSimulation
        );
    }

    /**
     * Spawns a physical entity with rigid body kinematics and geometric collider.
     */
    public function spawnBody(
        shape: Shape,
        type: BodyType = BodyDynamic,
        ?initialPos: FPVector2,
        ?initialAngle: FPNumber
    ): {entity: Entity, body: RigidBody, collider: Collider} {
        var entity = world.createEntity();
        var body = new RigidBody(type, initialPos, initialAngle);
        var collider = new Collider(shape);

        var massProps = (type == BodyStatic || type == BodyKinematic)
            ? {mass: FPNumber.ZERO, inertia: FPNumber.ZERO}
            : shape.computeMass(shape.density);
        body.setMass(massProps.mass, massProps.inertia);

        physics.addBody(entity, body, collider);
        return {entity: entity, body: body, collider: collider};
    }

    /**
     * Attaches an articulated joint constraint between two bodies.
     */
    public function addJoint(joint: Joint): Void {
        physics.addJoint(joint);
    }

    /**
     * Executes one complete simulation tick.
     */
    public function step(): Snapshot {
        return rollback.advanceFrame(fixedDeltaTime, function(dt: FPNumber) {
            physics.step(dt);
            world.step(dt);
        });
    }

    private function stepSimulation(frame: Int, dt: FPNumber): Void {
        physics.step(dt);
        world.step(dt);
    }

    private function captureSnapshot(frame: Int): Snapshot {
        var snapshot = new Snapshot(frame);
        snapshot.rngStateHigh = prng.getStateHigh();
        snapshot.rngStateLow = prng.getStateLow();

        // Capture live physical entity states
        for (rec in @:privateAccess physics.bodies) {
            snapshot.addEntityState(
                rec.entity,
                rec.body.transform.position,
                rec.body.transform.angle,
                rec.body.linearVelocity,
                rec.body.angularVelocity,
                rec.body.isAwake
            );
        }

        return snapshot;
    }

    private function restoreSnapshot(snapshot: Snapshot): Void {
        prng.restoreState(snapshot.rngStateHigh, snapshot.rngStateLow);

        // Restore entity kinematics
        for (e in snapshot.entities) {
            var rec = @:privateAccess physics.getRecord(e.entity);
            if (rec != null) {
                rec.body.transform.position.set(e.posX, e.posY);
                rec.body.transform.setAngle(e.angle);
                rec.body.linearVelocity.set(e.velX, e.velY);
                rec.body.angularVelocity = e.angVel;
                rec.body.isAwake = e.isAwake;
            }
        }
    }

    public function spawnCircle(radius: Float, x: Float, y: Float, isDynamic: Bool = true): Entity {
        var shape = new CircleShape(FPNumber.fromFloat(radius));
        var bType = isDynamic ? BodyDynamic : BodyStatic;
        var res = spawnBody(shape, bType, new FPVector2(FPNumber.fromFloat(x), FPNumber.fromFloat(y)));
        return res.entity;
    }

    public function spawnBox(halfWidth: Float, halfHeight: Float, x: Float, y: Float, isDynamic: Bool = true): Entity {
        var shape = new BoxShape(FPNumber.fromFloat(halfWidth), FPNumber.fromFloat(halfHeight));
        var bType = isDynamic ? BodyDynamic : BodyStatic;
        var res = spawnBody(shape, bType, new FPVector2(FPNumber.fromFloat(x), FPNumber.fromFloat(y)));
        return res.entity;
    }

    public function submitInput(player: Int, inputMask: Int): Void {
        rollback.setLocalInput(player, inputMask);
    }

    public function injectRollback(framesBack: Int, player: Int, inputMask: Int): Void {
        var targetFrame = rollback.currentFrame - framesBack;
        if (targetFrame < 0) targetFrame = 0;
        rollback.onRemoteInput(player, targetFrame, inputMask, fixedDeltaTime);
    }

    public function getStateForRenderer(): Dynamic {
        var bodyList: Array<Dynamic> = [];
        for (rec in @:privateAccess physics.bodies) {
            var isCircle = (rec.collider.shape.type == ShapeCircle);
            var isBox = (rec.collider.shape.type == ShapeBox);
            var rad = isCircle ? (cast(rec.collider.shape, CircleShape).radius.toFloat()) : 0.0;
            var hw = isBox ? (cast(rec.collider.shape, BoxShape).halfExtents.x.toFloat()) : 0.0;
            var hh = isBox ? (cast(rec.collider.shape, BoxShape).halfExtents.y.toFloat()) : 0.0;
            var aabb = rec.collider.shape.computeAABB(rec.body.transform);

            bodyList.push({
                id: rec.entity.getIndex(),
                type: rec.body.type == BodyStatic ? "static" : (rec.body.type == BodyKinematic ? "kinematic" : "dynamic"),
                x: rec.body.transform.position.x.toFloat(),
                y: rec.body.transform.position.y.toFloat(),
                angle: rec.body.transform.angle.toFloat(),
                vx: rec.body.linearVelocity.x.toFloat(),
                vy: rec.body.linearVelocity.y.toFloat(),
                shapeType: isCircle ? "circle" : (isBox ? "box" : "polygon"),
                radius: rad,
                halfWidth: hw,
                halfHeight: hh,
                minX: aabb.lowerBound.x.toFloat(),
                minY: aabb.lowerBound.y.toFloat(),
                maxX: aabb.upperBound.x.toFloat(),
                maxY: aabb.upperBound.y.toFloat(),
                isAwake: rec.body.isAwake
            });
        }

        var contactList: Array<Dynamic> = [];
        for (c in @:privateAccess physics.contacts) {
            contactList.push({
                px: c.point.x.toFloat(),
                py: c.point.y.toFloat(),
                nx: c.normal.x.toFloat(),
                ny: c.normal.y.toFloat(),
                depth: c.penetration.toFloat()
            });
        }

        var latestSnap = rollback.currentFrame > 0 ? rollback.getBuffer().getSnapshot(rollback.currentFrame - 1) : null;
        var chk = latestSnap != null ? latestSnap.checksum : 0;

        return {
            frame: rollback.currentFrame,
            rollbacks: rollback.getTotalRollbacks(),
            resimulated: rollback.getTotalResimulatedFrames(),
            checksum: chk,
            entityCount: world.getEntityCount(),
            bodies: bodyList,
            contacts: contactList
        };
    }

    public function clear(): Void {
        physics.clear();
        world.clear();
        rollback.clear();
        eventBus.clear();
    }
}
