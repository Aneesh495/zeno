package zeno.core;

import haxe.ds.Vector;

/**
 * Cache-optimized contiguous array list featuring O(1) swap-and-pop removal.
 * Avoids linear-time memory shifts when order preservation is not required,
 * making it ideal for simulation entity and collider arrays.
 */
class FastList<T> {
    private var items: Array<T>;
    public var length(get, never): Int;

    public function new(initialCapacity: Int = 16) {
        this.items = new Array<T>();
    }

    public inline function get_length(): Int {
        return items.length;
    }

    public inline function add(item: T): Void {
        items.push(item);
    }

    public inline function get(index: Int): T {
        return items[index];
    }

    public inline function set(index: Int, val: T): Void {
        items[index] = val;
    }

    /**
     * Removes the element at the specified index in O(1) time
     * by moving the last element into its slot and popping the tail.
     * @param index Target index to remove.
     * @return The element that was removed.
     */
    public function removeAtSwap(index: Int): T {
        var lastIdx = items.length - 1;
        if (index < 0 || index > lastIdx) return null;

        var removed = items[index];
        if (index != lastIdx) {
            items[index] = items[lastIdx];
        }
        items.pop();
        return removed;
    }

    /**
     * Searches and removes the first occurrence of item via swap-and-pop.
     */
    public function removeSwap(item: T): Bool {
        var idx = items.indexOf(item);
        if (idx >= 0) {
            removeAtSwap(idx);
            return true;
        }
        return false;
    }

    public inline function clear(): Void {
        while (items.length > 0) {
            items.pop();
        }
    }

    public inline function pop(): T {
        return items.pop();
    }

    public inline function contains(item: T): Bool {
        return items.indexOf(item) >= 0;
    }

    public inline function toArray(): Array<T> {
        return items.copy();
    }
}
