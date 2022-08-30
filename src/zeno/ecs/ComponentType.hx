package zeno.ecs;

import haxe.ds.StringMap;
import zeno.core.BitSet;

/**
 * Metadata descriptor for an ECS component type.
 * Tracks global type ID, component name, and memory layout.
 */
class ComponentType {
    private static var nextTypeId: Int = 0;
    private static var registryByName: StringMap<ComponentType> = new StringMap<ComponentType>();
    private static var registryById: Array<ComponentType> = new Array<ComponentType>();

    public var id(default, null): Int;
    public var name(default, null): String;
    public var sizeInBytes(default, null): Int;

    public function new(id: Int, name: String, sizeInBytes: Int) {
        this.id = id;
        this.name = name;
        this.sizeInBytes = sizeInBytes;
    }

    /**
     * Registers or retrieves a component type descriptor by name.
     * @param name Unique identifier for the component.
     * @param sizeInBytes Size in bytes for chunk memory calculations.
     * @return ComponentType instance.
     */
    public static function register(name: String, sizeInBytes: Int = 16): ComponentType {
        if (registryByName.exists(name)) {
            return registryByName.get(name);
        }
        var typeId = nextTypeId++;
        var ct = new ComponentType(typeId, name, sizeInBytes);
        registryByName.set(name, ct);
        registryById[typeId] = ct;
        return ct;
    }

    public static function getById(id: Int): ComponentType {
        if (id >= 0 && id < registryById.length) {
            return registryById[id];
        }
        return null;
    }

    public static function getByName(name: String): ComponentType {
        return registryByName.get(name);
    }

    public static inline function getTotalRegistered(): Int {
        return nextTypeId;
    }

    public static function resetRegistry(): Void {
        nextTypeId = 0;
        registryByName = new StringMap<ComponentType>();
        registryById = new Array<ComponentType>();
    }
}
