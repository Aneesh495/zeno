package zeno.ecs;

import haxe.ds.IntMap;
import zeno.core.BitSet;

/**
 * Unique structural archetype representing a specific combination of component types.
 * Owns contiguous chunks of entities sharing identical memory signatures.
 */
class Archetype {
    public var id(default, null): Int;
    public var mask(default, null): BitSet;
    public var componentTypes(default, null): Array<ComponentType>;
    public var chunks(default, null): Array<Chunk>;
    public var chunkCapacity(default, null): Int;

    private var typeToIndex: IntMap<Int>;
    private var totalEntitiesCount: Int;

    public function new(id: Int, componentTypes: Array<ComponentType>, chunkCapacity: Int = 512) {
        this.id = id;
        this.componentTypes = componentTypes.copy();
        this.chunkCapacity = chunkCapacity;
        this.chunks = new Array<Chunk>();
        this.typeToIndex = new IntMap<Int>();
        this.totalEntitiesCount = 0;

        // Build component bitmask and index lookup
        this.mask = new BitSet(64);
        for (i in 0...this.componentTypes.length) {
            var ct = this.componentTypes[i];
            mask.set(ct.id);
            typeToIndex.set(ct.id, i);
        }
    }

    public inline function hasComponentType(typeId: Int): Bool {
        return mask.get(typeId);
    }

    public inline function getComponentIndex(typeId: Int): Int {
        var idx = typeToIndex.get(typeId);
        return idx != null ? idx : -1;
    }

    public inline function getTotalEntities(): Int {
        return totalEntitiesCount;
    }

    /**
     * Allocates an entity within this archetype, creating a new chunk if necessary.
     * @return Object specifying chunk index and row where entity resides.
     */
    public function allocate(entity: Entity, initialComponents: Array<Dynamic>): {chunkIndex: Int, row: Int} {
        // Find existing chunk with space
        var targetChunkIdx = -1;
        for (i in 0...chunks.length) {
            if (!chunks[i].isFull()) {
                targetChunkIdx = i;
                break;
            }
        }

        if (targetChunkIdx < 0) {
            // Allocate new chunk
            var newChunk = new Chunk(this, chunkCapacity);
            chunks.push(newChunk);
            targetChunkIdx = chunks.length - 1;
        }

        var row = chunks[targetChunkIdx].allocateEntity(entity, initialComponents);
        totalEntitiesCount++;
        return {chunkIndex: targetChunkIdx, row: row};
    }

    /**
     * Removes an entity from a chunk via swap-and-pop.
     * @return Swapped entity if one was relocated to this row, or Entity.NONE.
     */
    public function deallocate(chunkIndex: Int, row: Int): Entity {
        if (chunkIndex < 0 || chunkIndex >= chunks.length) return Entity.NONE;

        var swapped = chunks[chunkIndex].removeEntity(row);
        totalEntitiesCount--;

        // Clean up empty trailing chunks if needed
        if (chunks[chunkIndex].isEmpty() && chunks.length > 1) {
            var lastChunk = chunks[chunks.length - 1];
            if (lastChunk.isEmpty() && chunkIndex == chunks.length - 1) {
                chunks.pop();
            }
        }

        return swapped;
    }

    public function clear(): Void {
        for (c in chunks) {
            c.clear();
        }
        while (chunks.length > 0) chunks.pop();
        totalEntitiesCount = 0;
    }
}
