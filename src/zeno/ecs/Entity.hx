package zeno.ecs;

import haxe.Int32;

/**
 * Generational entity identifier.
 * Packed as a 32-bit unsigned integer:
 * - Lower 20 bits: Entity Index (supports up to 1,048,575 concurrent entities)
 * - Upper 12 bits: Generation counter (supports up to 4,095 reuses per slot)
 * Eliminates use-after-free and stale reference errors.
 */
abstract Entity(Int32) from Int32 to Int32 {
    public static inline var INDEX_BITS: Int = 20;
    public static inline var INDEX_MASK: Int32 = (1 << INDEX_BITS) - 1; // 0x000FFFFF
    public static inline var GENERATION_BITS: Int = 12;
    public static inline var GENERATION_MASK: Int32 = (1 << GENERATION_BITS) - 1; // 0x00000FFF

    public static var NONE(default, never): Entity = new Entity(0);

    public inline function new(raw: Int32) {
        this = raw;
    }

    public static inline function make(index: Int, generation: Int): Entity {
        var raw: Int32 = (index & INDEX_MASK) | ((generation & GENERATION_MASK) << INDEX_BITS);
        return new Entity(raw);
    }

    public inline function getIndex(): Int {
        return this & INDEX_MASK;
    }

    public inline function getGeneration(): Int {
        return (this >>> INDEX_BITS) & GENERATION_MASK;
    }

    public inline function isValid(): Bool {
        return this != 0;
    }

    public inline function getRaw(): Int32 {
        return this;
    }

    @:op(A == B)
    public static inline function eq(a: Entity, b: Entity): Bool {
        return a.getRaw() == b.getRaw();
    }

    @:op(A != B)
    public static inline function neq(a: Entity, b: Entity): Bool {
        return a.getRaw() != b.getRaw();
    }

    public function toString(): String {
        return "Entity(" + getIndex() + "v" + getGeneration() + ")";
    }
}
