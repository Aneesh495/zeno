package zeno.ecs;

import zeno.math.FPNumber;

/**
 * Interface for simulation systems.
 * Systems encapsulate discrete domain logic (physics, motion, combat, netcode)
 * executing over filtered entity queries.
 */
interface ISystem {
    public var name(default, null): String;
    public var enabled: Bool;
    public var priority: Int;

    public function init(world: World): Void;
    public function update(world: World, dt: FPNumber): Void;
    public function destroy(world: World): Void;
}

/**
 * Base abstract system providing common defaults.
 */
class BaseSystem implements ISystem {
    public var name(default, null): String;
    public var enabled: Bool;
    public var priority: Int;

    public function new(name: String, priority: Int = 0) {
        this.name = name;
        this.priority = priority;
        this.enabled = true;
    }

    public function init(world: World): Void {}
    public function update(world: World, dt: FPNumber): Void {}
    public function destroy(world: World): Void {}
}
