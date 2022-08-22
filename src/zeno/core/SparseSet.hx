package zeno.core;

import haxe.ds.Vector;

/**
 * Sparse Set data structure for integer identifiers.
 * Provides O(1) insertion, O(1) lookup, O(1) removal, and
 * cache-optimal contiguous iteration over dense active elements.
 */
class SparseSet {
    private var sparse: Vector<Int>;
    private var dense: Array<Int>;
    private var sparseCapacity: Int;

    public var size(get, never): Int;

    public function new(maxId: Int = 1024) {
        this.sparseCapacity = maxId > 0 ? maxId : 1024;
        this.sparse = new Vector<Int>(sparseCapacity);
        for (i in 0...sparseCapacity) {
            this.sparse[i] = -1;
        }
        this.dense = new Array<Int>();
    }

    public inline function get_size(): Int {
        return dense.length;
    }

    public function contains(id: Int): Bool {
        if (id < 0 || id >= sparseCapacity) return false;
        var denseIndex = sparse[id];
        return denseIndex >= 0 && denseIndex < dense.length && dense[denseIndex] == id;
    }

    public function add(id: Int): Bool {
        if (id < 0) return false;
        ensureCapacity(id + 1);
        if (contains(id)) return false;

        var denseIndex = dense.length;
        dense.push(id);
        sparse[id] = denseIndex;
        return true;
    }

    public function remove(id: Int): Bool {
        if (!contains(id)) return false;

        var denseIndex = sparse[id];
        var lastDenseIndex = dense.length - 1;
        var lastId = dense[lastDenseIndex];

        // Swap last element into the removed slot
        dense[denseIndex] = lastId;
        sparse[lastId] = denseIndex;

        // Invalidate removed id
        sparse[id] = -1;
        dense.pop();
        return true;
    }

    public function getDenseArray(): Array<Int> {
        return dense;
    }

    public inline function getAt(index: Int): Int {
        return dense[index];
    }

    public function clear(): Void {
        var len = dense.length;
        for (i in 0...len) {
            var id = dense[i];
            if (id >= 0 && id < sparseCapacity) {
                sparse[id] = -1;
            }
        }
        while (dense.length > 0) {
            dense.pop();
        }
    }

    private function ensureCapacity(required: Int): Void {
        if (required <= sparseCapacity) return;
        var newCap = sparseCapacity;
        while (newCap < required) {
            newCap = newCap << 1;
        }
        var newSparse = new Vector<Int>(newCap);
        for (i in 0...sparseCapacity) {
            newSparse[i] = sparse[i];
        }
        for (i in sparseCapacity...newCap) {
            newSparse[i] = -1;
        }
        this.sparse = newSparse;
        this.sparseCapacity = newCap;
    }
}
