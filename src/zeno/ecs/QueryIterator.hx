package zeno.ecs;

/**
 * High-performance stateful iterator over matching query entities.
 * Avoids array allocations by traversing chunks sequentially.
 */
class QueryIterator {
    private var query: Query;
    private var archIndex: Int;
    private var chunkIndex: Int;
    private var rowIndex: Int;
    private var currentEntity: Entity;

    public function new(query: Query) {
        this.query = query;
        reset();
    }

    public function reset(): Void {
        this.archIndex = 0;
        this.chunkIndex = 0;
        this.rowIndex = 0;
        this.currentEntity = Entity.NONE;
    }

    public function hasNext(): Bool {
        var archetypes = query.matchedArchetypes;
        while (archIndex < archetypes.length) {
            var arch = archetypes[archIndex];
            var chunks = arch.chunks;
            while (chunkIndex < chunks.length) {
                var chunk = chunks[chunkIndex];
                if (rowIndex < chunk.count) {
                    currentEntity = chunk.entities[rowIndex];
                    return true;
                }
                // Advance to next chunk
                chunkIndex++;
                rowIndex = 0;
            }
            // Advance to next archetype
            archIndex++;
            chunkIndex = 0;
            rowIndex = 0;
        }
        return false;
    }

    public function next(): Entity {
        var ent = currentEntity;
        rowIndex++;
        return ent;
    }

    public inline function getCurrentChunk(): Chunk {
        var arch = query.matchedArchetypes[archIndex];
        return arch.chunks[chunkIndex];
    }

    public inline function getCurrentRow(): Int {
        return rowIndex;
    }
}
