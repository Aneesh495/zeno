package zeno.ecs;

import zeno.math.FPNumber;
import zeno.ecs.System.ISystem;

/**
 * Composite execution group for systems.
 * Sorts child systems by priority and executes them sequentially.
 */
class SystemGroup implements ISystem {
    public var name(default, null): String;
    public var enabled: Bool;
    public var priority: Int;

    private var systems: Array<ISystem>;

    public function new(name: String, priority: Int = 0) {
        this.name = name;
        this.priority = priority;
        this.enabled = true;
        this.systems = new Array<ISystem>();
    }

    public function addSystem(system: ISystem): SystemGroup {
        systems.push(system);
        sortSystems();
        return this;
    }

    public function removeSystem(system: ISystem): Bool {
        var idx = systems.indexOf(system);
        if (idx >= 0) {
            systems.splice(idx, 1);
            return true;
        }
        return false;
    }

    public function init(world: World): Void {
        for (s in systems) {
            s.init(world);
        }
    }

    public function update(world: World, dt: FPNumber): Void {
        if (!enabled) return;
        var len = systems.length;
        for (i in 0...len) {
            var sys = systems[i];
            if (sys.enabled) {
                sys.update(world, dt);
            }
        }
    }

    public function destroy(world: World): Void {
        for (s in systems) {
            s.destroy(world);
        }
        while (systems.length > 0) systems.pop();
    }

    public inline function getSystems(): Array<ISystem> {
        return systems;
    }

    private function sortSystems(): Void {
        systems.sort(function(a, b) return a.priority - b.priority);
    }
}
