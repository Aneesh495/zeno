# Zeno API Reference & Integration Guide

Complete programmer reference for the Zeno Deterministic Physical Simulation & Rollback Runtime. Covers Haxe native types, JavaScript visualizer APIs, Native C FFI bindings, and Python telemetry utilities.

---

## 1. Top-Level Engine Facade (`zeno.Zeno`)

The primary entry point coordinating the ECS world, physics engine, rollback manager, and event dispatcher.

```haxe
package zeno;

class Zeno {
    public var world(default, null): World;
    public var physics(default, null): PhysicsWorld;
    public var rollback(default, null): RollbackManager;
    public var eventBus(default, null): EventBus;
    public var prng(default, null): FPRandom;
    public var fixedDeltaTime(default, null): FPNumber;

    /**
     * Initializes a new deterministic simulation instance.
     * @param seed Initial PRNG seed for deterministic random streams (default: 42)
     * @param players Number of participating network players (default: 2)
     * @param tickRateHz Simulation update frequency in Hertz (default: 60)
     */
    public function new(seed: Int = 42, players: Int = 2, tickRateHz: Int = 60);

    /**
     * Spawns a physical entity with rigid body kinematics and a geometric collider.
     */
    public function spawnBody(
        shape: Shape,
        type: BodyType = BodyDynamic,
        ?initialPos: FPVector2,
        ?initialAngle: FPNumber
    ): {entity: Entity, body: RigidBody, collider: Collider};

    /**
     * Helper to spawn a circular dynamic or static body.
     */
    public function spawnCircle(radius: Float, x: Float, y: Float, isDynamic: Bool = true): Entity;

    /**
     * Helper to spawn an oriented box dynamic or static body.
     */
    public function spawnBox(halfWidth: Float, halfHeight: Float, x: Float, y: Float, isDynamic: Bool = true): Entity;

    /**
     * Attaches an articulated joint constraint between two bodies.
     */
    public function addJoint(joint: Joint): Void;

    /**
     * Submits local player input bitmask for the current simulation frame.
     */
    public function submitInput(player: Int, inputMask: Int): Void;

    /**
     * Injects remote input from a past frame to trigger speculative rollback and resimulation.
     */
    public function injectRollback(framesBack: Int, player: Int, inputMask: Int): Void;

    /**
     * Advances the simulation by exactly one fixed-point tick (1/60th second).
     * Automatically captures a snapshot, executes physics, and updates the ECS.
     */
    public function step(): Snapshot;

    /**
     * Returns a JSON-serializable snapshot of physical bodies, contacts, and rollback telemetry.
     */
    public function getStateForRenderer(): Dynamic;

    /**
     * Resets and clears all internal entities, bodies, constraints, and snapshot buffers.
     */
    public function clear(): Void;
}
```

---

## 2. Fixed-Point Mathematics (`zeno.math`)

### `FPNumber`
A Q16.16 signed fixed-point value representing numbers with 16 fractional bits.

```haxe
var a = FPNumber.fromInt(5);
var b = FPNumber.fromFloat(2.5);
var c = a + b; // 7.5
var d = a * b; // 12.5 (saturating on overflow)
var intVal = c.toInt(); // 7
var floatVal = c.toFloat(); // 7.5
```

### `FPMath`
Deterministic mathematical functions:
* `FPMath.sqrt(x: FPNumber): FPNumber`: Pure integer radical extraction.
* `FPMath.sin(theta: FPNumber): FPNumber`: CORDIC circular sine.
* `FPMath.cos(theta: FPNumber): FPNumber`: CORDIC circular cosine.
* `FPMath.atan2(y: FPNumber, x: FPNumber): FPNumber`: CORDIC four-quadrant arctangent.
* `FPMath.clamp(val, min, max)` / `FPMath.min(a, b)` / `FPMath.max(a, b)`.

### `FPVector2`
2D fixed-point vector with dot, cross, length, distance, and normalization:
```haxe
var v1 = new FPVector2(FPNumber.fromInt(3), FPNumber.fromInt(4));
var len = v1.length(); // 5.0
var unit = v1.normalize(); // (0.6, 0.8)
var dot = v1.dot(new FPVector2(FPNumber.ONE, FPNumber.ZERO)); // 3.0
```

---

## 3. Archetype Entity Component System (`zeno.ecs`)

### `World`
```haxe
var world = new World(1024);

// Create generational entity handle
var entity = world.createEntity();

// Add components
world.addComponent(entity, PositionComponent.TYPE, new PositionComponent(10, 20));
world.addComponent(entity, VelocityComponent.TYPE, new VelocityComponent(1, 0));

// Zero-allocation filtered query
world.query()
    .with(PositionComponent.TYPE)
    .with(VelocityComponent.TYPE)
    .without(StaticTag.TYPE)
    .forEach(function(e: Entity, chunk: Chunk, idx: Int) {
        // High-speed contiguous array access
    });

// Recycle entity slot safely
world.destroyEntity(entity);
```

---

## 4. Physics Engine & Constraints (`zeno.physics`)

### Rigid Bodies & Colliders
```haxe
var boxShape = new BoxShape(FPNumber.ONE, FPNumber.fromInt(2));
var collider = new Collider(boxShape, FPNumber.fromFloat(0.3), FPNumber.fromFloat(0.1));
var body = new RigidBody(BodyDynamic, new FPVector2(0, 10));

physicsWorld.addBody(entity, body, collider);
```

### Joints
```haxe
// Distance Joint
var joint = new DistanceJoint(entityA, entityB, anchorA, anchorB, targetDistance);
physicsWorld.addJoint(joint);

// Revolute (Pin) Joint
var revJoint = new RevoluteJoint(entityA, entityB, sharedAnchor);
physicsWorld.addJoint(revJoint);
```

---

## 5. JavaScript / Web API

When compiled to JavaScript (`bin/zeno.js`), the engine is exposed globally on `window.Zeno` (browser) or `exports.Zeno` (Node.js):

```javascript
// Browser / Node.js instantiation
const engine = new window.Zeno(1337);

// Spawn static boundaries and dynamic physical bodies
engine.spawnBox(20.0, 1.0, 0.0, -5.0, false); // Ground
engine.spawnCircle(1.0, 0.0, 10.0, true);      // Dynamic Sphere

// Step simulation at 60Hz
engine.submitInput(0, 0x01); // Player 0 presses Action button
engine.step();

// Extract render state for HTML5 Canvas
const state = engine.getStateForRenderer();
console.log(`Frame: ${state.frame}, Hash: 0x${state.checksum.toString(16)}`);
```

---

## 6. Native C ABI (`c_interop/zeno_api.h`)

Include the C99 header to interface directly with Zeno from native code:

```c
#include "zeno_api.h"

// Fixed-point conversions
zeno_fp_t speed = zeno_fp_from_float(9.81f);
zeno_vec2_t gravity = { 0, zeno_fp_from_float(-9.81f) };

// Shape configuration
zeno_shape_desc_t desc;
desc.type = ZENO_SHAPE_CIRCLE;
desc.data.circle.radius = zeno_fp_from_float(0.5f);
desc.density = zeno_fp_from_float(1.0f);
desc.friction = zeno_fp_from_float(0.2f);
desc.restitution = zeno_fp_from_float(0.8f);
```
