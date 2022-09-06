package zeno.ecs;

import zeno.core.BitSet;

/**
 * Filtered view over ECS archetypes.
 * Caches matched archetypes to provide zero-overhead linear chunk traversal.
 */
class Query {
    public var allMask(default, null): BitSet;
    public var anyMask(default, null): BitSet;
    public var noneMask(default, null): BitSet;
    public var matchedArchetypes(default, null): Array<Archetype>;

    private var hasAnyFilter: Bool;
    private var hasNoneFilter: Bool;

    public function new() {
        this.allMask = new BitSet(64);
        this.anyMask = new BitSet(64);
        this.noneMask = new BitSet(64);
        this.matchedArchetypes = new Array<Archetype>();
        this.hasAnyFilter = false;
        this.hasNoneFilter = false;
    }

    /**
     * Entity must contain this component.
     */
    public function with(ct: ComponentType): Query {
        allMask.set(ct.id);
        return this;
    }

    /**
     * Entity must contain at least one component in the Any filter.
     */
    public function withAny(ct: ComponentType): Query {
        anyMask.set(ct.id);
        hasAnyFilter = true;
        return this;
    }

    /**
     * Entity must not contain this component.
     */
    public function without(ct: ComponentType): Query {
        noneMask.set(ct.id);
        hasNoneFilter = true;
        return this;
    }

    /**
     * Tests whether an archetype satisfies the query constraints.
     */
    public function matches(arch: Archetype): Bool {
        // Must contain all components in allMask
        if (!arch.mask.containsAll(allMask)) return false;

        // If any filter is specified, must intersect
        if (hasAnyFilter && !arch.mask.intersects(anyMask)) return false;

        // If none filter is specified, must NOT intersect
        if (hasNoneFilter && arch.mask.intersects(noneMask)) return false;

        return true;
    }

    /**
     * Registers an archetype if it matches the filter criteria.
     */
    public function onArchetypeCreated(arch: Archetype): Void {
        if (matches(arch)) {
            if (matchedArchetypes.indexOf(arch) < 0) {
                matchedArchetypes.push(arch);
            }
        }
    }

    /**
     * Evaluates all archetypes from the graph.
     */
    public function updateMatchedArchetypes(allArchetypes: Array<Archetype>): Void {
        while (matchedArchetypes.length > 0) matchedArchetypes.pop();
        for (arch in allArchetypes) {
            if (matches(arch)) {
                matchedArchetypes.push(arch);
            }
        }
    }

    /**
     * Computes the total number of live entities matching this query.
     */
    public function countEntities(): Int {
        var total = 0;
        for (arch in matchedArchetypes) {
            total += arch.getTotalEntities();
        }
        return total;
    }

    /**
     * Iterates over all matching entities across contiguous chunks.
     */
    public inline function forEach(callback: (entity: Entity, chunk: Chunk, row: Int) -> Void): Void {
        for (arch in matchedArchetypes) {
            var chunks = arch.chunks;
            var numChunks = chunks.length;
            for (c in 0...numChunks) {
                var chunk = chunks[c];
                var count = chunk.count;
                var ents = chunk.entities;
                for (r in 0...count) {
                    callback(ents[r], chunk, r);
                }
            }
        }
    }
}
