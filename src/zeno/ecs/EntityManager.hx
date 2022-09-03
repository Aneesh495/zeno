package zeno.ecs;

import haxe.ds.Vector;

/**
 * Internal entity location descriptor within archetype chunk storage.
 */
class EntityLocation {
    public var archetype: Archetype;
    public var chunkIndex: Int;
    public var row: Int;

    public function new(archetype: Archetype, chunkIndex: Int, row: Int) {
        this.archetype = archetype;
        this.chunkIndex = chunkIndex;
        this.row = row;
    }
}

/**
 * Generational entity manager.
 * Manages entity ID recycling with generation counters,
 * tracks entity-to-chunk locations, and drives archetype migrations.
 */
class EntityManager {
    private var generations: Vector<Int>;
    private var locations: Vector<EntityLocation>;
    private var freeIndices: Array<Int>;
    private var nextUnusedIndex: Int;
    private var capacity: Int;
    private var activeEntityCount: Int;
    private var graph: ArchetypeGraph;

    public function new(graph: ArchetypeGraph, initialCapacity: Int = 1024) {
        this.graph = graph;
        this.capacity = initialCapacity > 0 ? initialCapacity : 1024;
        this.generations = new Vector<Int>(capacity);
        this.locations = new Vector<EntityLocation>(capacity);
        this.freeIndices = new Array<Int>();
        this.nextUnusedIndex = 1; // 0 reserved for Entity.NONE
        this.activeEntityCount = 0;

        for (i in 0...capacity) {
            generations[i] = 1; // Start generation at 1
            locations[i] = null;
        }
    }

    public inline function getActiveCount(): Int return activeEntityCount;
    public inline function getCapacity(): Int return capacity;

    /**
     * Spawns a new entity into the empty archetype or specified initial archetype.
     */
    public function createEntity(?initialArchetype: Archetype, ?initialComponents: Array<Dynamic>): Entity {
        var index = allocateIndex();
        var gen = generations[index];
        var entity = Entity.make(index, gen);

        var targetArch = initialArchetype != null ? initialArchetype : graph.getEmptyArchetype();
        var loc = targetArch.allocate(entity, initialComponents);

        locations[index] = new EntityLocation(targetArch, loc.chunkIndex, loc.row);
        activeEntityCount++;
        return entity;
    }

    /**
     * Validates whether an entity handle is alive and current.
     */
    public function isAlive(entity: Entity): Bool {
        if (!entity.isValid()) return false;
        var idx = entity.getIndex();
        if (idx <= 0 || idx >= capacity) return false;
        return generations[idx] == entity.getGeneration() && locations[idx] != null;
    }

    /**
     * Destroys an entity, removes it from its archetype chunk, and recycles its index.
     */
    public function destroyEntity(entity: Entity): Bool {
        if (!isAlive(entity)) return false;

        var idx = entity.getIndex();
        var loc = locations[idx];
        var swapped = loc.archetype.deallocate(loc.chunkIndex, loc.row);

        // If another entity was swapped into this row, update its location
        if (swapped.isValid()) {
            var swappedIdx = swapped.getIndex();
            if (locations[swappedIdx] != null) {
                locations[swappedIdx].row = loc.row;
                locations[swappedIdx].chunkIndex = loc.chunkIndex;
            }
        }

        locations[idx] = null;
        // Increment generation on destruction to invalidate stale handles
        generations[idx] = (generations[idx] + 1) & Entity.GENERATION_MASK;
        if (generations[idx] == 0) generations[idx] = 1;

        freeIndices.push(idx);
        activeEntityCount--;
        return true;
    }

    /**
     * Adds a component to an entity, migrating it to the target archetype.
     */
    public function addComponent(entity: Entity, componentType: ComponentType, value: Dynamic): Void {
        if (!isAlive(entity)) return;

        var idx = entity.getIndex();
        var loc = locations[idx];
        var currentArch = loc.archetype;

        // If already present, just overwrite value
        if (currentArch.hasComponentType(componentType.id)) {
            var compIdx = currentArch.getComponentIndex(componentType.id);
            currentArch.chunks[loc.chunkIndex].setComponent(compIdx, loc.row, value);
            return;
        }

        var targetArch = graph.getAddTransition(currentArch, componentType);

        // Gather existing component values
        var newComponents = new Array<Dynamic>();
        for (i in 0...targetArch.componentTypes.length) {
            var ct = targetArch.componentTypes[i];
            if (ct.id == componentType.id) {
                newComponents.push(value);
            } else {
                var oldCompIdx = currentArch.getComponentIndex(ct.id);
                var oldVal = currentArch.chunks[loc.chunkIndex].getComponent(oldCompIdx, loc.row);
                newComponents.push(oldVal);
            }
        }

        // Deallocate from old archetype
        var swapped = currentArch.deallocate(loc.chunkIndex, loc.row);
        if (swapped.isValid()) {
            var swappedIdx = swapped.getIndex();
            if (locations[swappedIdx] != null) {
                locations[swappedIdx].row = loc.row;
                locations[swappedIdx].chunkIndex = loc.chunkIndex;
            }
        }

        // Allocate in new archetype
        var newLoc = targetArch.allocate(entity, newComponents);
        locations[idx].archetype = targetArch;
        locations[idx].chunkIndex = newLoc.chunkIndex;
        locations[idx].row = newLoc.row;
    }

    /**
     * Removes a component from an entity, migrating it to the smaller archetype.
     */
    public function removeComponent(entity: Entity, componentType: ComponentType): Void {
        if (!isAlive(entity)) return;

        var idx = entity.getIndex();
        var loc = locations[idx];
        var currentArch = loc.archetype;

        if (!currentArch.hasComponentType(componentType.id)) return;

        var targetArch = graph.getRemoveTransition(currentArch, componentType);

        // Gather remaining components
        var newComponents = new Array<Dynamic>();
        for (ct in targetArch.componentTypes) {
            var oldCompIdx = currentArch.getComponentIndex(ct.id);
            var oldVal = currentArch.chunks[loc.chunkIndex].getComponent(oldCompIdx, loc.row);
            newComponents.push(oldVal);
        }

        var swapped = currentArch.deallocate(loc.chunkIndex, loc.row);
        if (swapped.isValid()) {
            var swappedIdx = swapped.getIndex();
            if (locations[swappedIdx] != null) {
                locations[swappedIdx].row = loc.row;
                locations[swappedIdx].chunkIndex = loc.chunkIndex;
            }
        }

        var newLoc = targetArch.allocate(entity, newComponents);
        locations[idx].archetype = targetArch;
        locations[idx].chunkIndex = newLoc.chunkIndex;
        locations[idx].row = newLoc.row;
    }

    public function getComponent(entity: Entity, componentType: ComponentType): Dynamic {
        if (!isAlive(entity)) return null;

        var idx = entity.getIndex();
        var loc = locations[idx];
        var compIdx = loc.archetype.getComponentIndex(componentType.id);
        if (compIdx < 0) return null;

        return loc.archetype.chunks[loc.chunkIndex].getComponent(compIdx, loc.row);
    }

    public function setComponent(entity: Entity, componentType: ComponentType, value: Dynamic): Void {
        if (!isAlive(entity)) return;

        var idx = entity.getIndex();
        var loc = locations[idx];
        var compIdx = loc.archetype.getComponentIndex(componentType.id);
        if (compIdx < 0) return;

        loc.archetype.chunks[loc.chunkIndex].setComponent(compIdx, loc.row, value);
    }

    public inline function hasComponent(entity: Entity, componentType: ComponentType): Bool {
        if (!isAlive(entity)) return false;
        var idx = entity.getIndex();
        return locations[idx].archetype.hasComponentType(componentType.id);
    }

    public inline function getArchetype(entity: Entity): Archetype {
        if (!isAlive(entity)) return null;
        return locations[entity.getIndex()].archetype;
    }

    private function allocateIndex(): Int {
        if (freeIndices.length > 0) {
            return freeIndices.pop();
        }

        var idx = nextUnusedIndex++;
        if (idx >= capacity) {
            ensureCapacity(capacity << 1);
        }
        return idx;
    }

    private function ensureCapacity(newCap: Int): Void {
        var oldCap = capacity;
        var newGen = new Vector<Int>(newCap);
        var newLoc = new Vector<EntityLocation>(newCap);

        for (i in 0...oldCap) {
            newGen[i] = generations[i];
            newLoc[i] = locations[i];
        }
        for (i in oldCap...newCap) {
            newGen[i] = 1;
            newLoc[i] = null;
        }

        this.generations = newGen;
        this.locations = newLoc;
        this.capacity = newCap;
    }

    public function clear(): Void {
        for (i in 0...capacity) {
            locations[i] = null;
            generations[i] = 1;
        }
        while (freeIndices.length > 0) freeIndices.pop();
        nextUnusedIndex = 1;
        activeEntityCount = 0;
    }
}
