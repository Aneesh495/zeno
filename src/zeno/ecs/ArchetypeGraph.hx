package zeno.ecs;

import haxe.ds.IntMap;
import haxe.ds.StringMap;
import zeno.core.BitSet;

/**
 * State transition graph connecting Archetypes.
 * Caches component addition and removal edges (A + C -> A' and A - C -> A'')
 * enabling O(1) archetype migration without repeated hashing or array allocation.
 */
class ArchetypeGraph {
    private var archetypes: Array<Archetype>;
    private var archetypeBySignature: StringMap<Archetype>;
    private var addEdges: IntMap<IntMap<Archetype>>; // archetypeId -> (componentTypeId -> targetArchetype)
    private var removeEdges: IntMap<IntMap<Archetype>>; // archetypeId -> (componentTypeId -> targetArchetype)
    private var nextArchetypeId: Int;
    private var emptyArchetype: Archetype;

    public function new() {
        this.archetypes = new Array<Archetype>();
        this.archetypeBySignature = new StringMap<Archetype>();
        this.addEdges = new IntMap<IntMap<Archetype>>();
        this.removeEdges = new IntMap<IntMap<Archetype>>();
        this.nextArchetypeId = 0;

        // Root empty archetype (no components)
        this.emptyArchetype = createArchetype([]);
    }

    public inline function getEmptyArchetype(): Archetype {
        return emptyArchetype;
    }

    public inline function getAllArchetypes(): Array<Archetype> {
        return archetypes;
    }

    /**
     * Finds or creates an archetype for an exact set of component types.
     */
    public function getOrCreateArchetype(types: Array<ComponentType>): Archetype {
        if (types == null || types.length == 0) return emptyArchetype;

        // Sort by component type ID to guarantee canonical signature
        var sorted = types.copy();
        sorted.sort(function(a, b) return a.id - b.id);

        var sig = buildSignature(sorted);
        if (archetypeBySignature.exists(sig)) {
            return archetypeBySignature.get(sig);
        }

        return createArchetype(sorted);
    }

    /**
     * Traverses or creates an archetype transition edge for adding a component type.
     */
    public function getAddTransition(source: Archetype, addedType: ComponentType): Archetype {
        var edges = addEdges.get(source.id);
        if (edges == null) {
            edges = new IntMap<Archetype>();
            addEdges.set(source.id, edges);
        }

        var cached = edges.get(addedType.id);
        if (cached != null) return cached;

        // Verify not already present
        if (source.hasComponentType(addedType.id)) {
            edges.set(addedType.id, source);
            return source;
        }

        var newTypes = source.componentTypes.copy();
        newTypes.push(addedType);
        var target = getOrCreateArchetype(newTypes);

        // Cache bidirectional transitions
        edges.set(addedType.id, target);

        var revEdges = removeEdges.get(target.id);
        if (revEdges == null) {
            revEdges = new IntMap<Archetype>();
            removeEdges.set(target.id, revEdges);
        }
        revEdges.set(addedType.id, source);

        return target;
    }

    /**
     * Traverses or creates an archetype transition edge for removing a component type.
     */
    public function getRemoveTransition(source: Archetype, removedType: ComponentType): Archetype {
        var edges = removeEdges.get(source.id);
        if (edges == null) {
            edges = new IntMap<Archetype>();
            removeEdges.set(source.id, edges);
        }

        var cached = edges.get(removedType.id);
        if (cached != null) return cached;

        if (!source.hasComponentType(removedType.id)) {
            edges.set(removedType.id, source);
            return source;
        }

        var newTypes = new Array<ComponentType>();
        for (ct in source.componentTypes) {
            if (ct.id != removedType.id) {
                newTypes.push(ct);
            }
        }
        var target = getOrCreateArchetype(newTypes);

        edges.set(removedType.id, target);

        var revEdges = addEdges.get(target.id);
        if (revEdges == null) {
            revEdges = new IntMap<Archetype>();
            addEdges.set(target.id, revEdges);
        }
        revEdges.set(removedType.id, source);

        return target;
    }

    private function createArchetype(sortedTypes: Array<ComponentType>): Archetype {
        var id = nextArchetypeId++;
        var arch = new Archetype(id, sortedTypes);
        archetypes.push(arch);
        var sig = buildSignature(sortedTypes);
        archetypeBySignature.set(sig, arch);
        return arch;
    }

    private function buildSignature(sortedTypes: Array<ComponentType>): String {
        var buf = new StringBuf();
        for (i in 0...sortedTypes.length) {
            if (i > 0) buf.add(",");
            buf.add(sortedTypes[i].id);
        }
        return buf.toString();
    }
}
