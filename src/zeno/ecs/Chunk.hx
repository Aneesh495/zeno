package zeno.ecs;

import haxe.ds.Vector;

/**
 * Contiguous storage block for entities belonging to a specific archetype.
 * Stores entities and components in Struct-of-Arrays (SoA) layout.
 * Employs swap-and-pop removal to maintain 100% dense contiguous memory.
 */
class Chunk {
    public var capacity(default, null): Int;
    public var count(default, null): Int;
    public var entities: Vector<Entity>;
    public var componentArrays: Array<Array<Dynamic>>;
    public var archetype: Archetype;

    public function new(archetype: Archetype, capacity: Int = 512) {
        this.archetype = archetype;
        this.capacity = capacity > 0 ? capacity : 512;
        this.count = 0;
        this.entities = new Vector<Entity>(this.capacity);

        var numComponents = archetype.componentTypes.length;
        this.componentArrays = new Array<Array<Dynamic>>();
        for (i in 0...numComponents) {
            this.componentArrays.push(new Array<Dynamic>());
        }
    }

    public inline function isFull(): Bool return count >= capacity;
    public inline function isEmpty(): Bool return count == 0;

    /**
     * Appends an entity and its initial component values to the chunk.
     * @return Row index within this chunk where entity was placed.
     */
    public function allocateEntity(entity: Entity, initialComponents: Array<Dynamic>): Int {
        if (isFull()) return -1;

        var row = count;
        entities[row] = entity;

        var numComps = archetype.componentTypes.length;
        for (i in 0...numComps) {
            var compVal = (initialComponents != null && i < initialComponents.length) ? initialComponents[i] : null;
            componentArrays[i][row] = compVal;
        }

        count++;
        return row;
    }

    /**
     * Removes an entity at the specified row in O(1) time via swap-and-pop.
     * @param row Row index to remove.
     * @return The entity that was swapped into this row, or Entity.NONE if it was the last row.
     */
    public function removeEntity(row: Int): Entity {
        if (row < 0 || row >= count) return Entity.NONE;

        var lastRow = count - 1;
        var swappedEntity = Entity.NONE;

        if (row != lastRow) {
            // Swap last entity and components into vacated row
            swappedEntity = entities[lastRow];
            entities[row] = swappedEntity;

            var numComps = archetype.componentTypes.length;
            for (i in 0...numComps) {
                componentArrays[i][row] = componentArrays[i][lastRow];
                componentArrays[i][lastRow] = null;
            }
        } else {
            var numComps = archetype.componentTypes.length;
            for (i in 0...numComps) {
                componentArrays[i][lastRow] = null;
            }
        }

        entities[lastRow] = Entity.NONE;
        count--;
        return swappedEntity;
    }

    public inline function getComponent(compIndex: Int, row: Int): Dynamic {
        return componentArrays[compIndex][row];
    }

    public inline function setComponent(compIndex: Int, row: Int, value: Dynamic): Void {
        componentArrays[compIndex][row] = value;
    }

    public function clear(): Void {
        for (i in 0...capacity) {
            entities[i] = Entity.NONE;
        }
        for (arr in componentArrays) {
            while (arr.length > 0) arr.pop();
        }
        count = 0;
    }
}
