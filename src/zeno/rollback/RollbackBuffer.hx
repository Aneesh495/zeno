package zeno.rollback;

import haxe.ds.Vector;

/**
 * Power-of-two circular ring buffer storing historical world snapshots.
 * Provides O(1) random access retrieval by simulation frame index.
 */
class RollbackBuffer {
    private var snapshots: Vector<Snapshot>;
    private var capacity: Int;
    private var mask: Int;

    public function new(requestedCapacity: Int = 128) {
        var cap = 1;
        while (cap < requestedCapacity) {
            cap = cap << 1;
        }
        this.capacity = cap;
        this.mask = cap - 1;
        this.snapshots = new Vector<Snapshot>(capacity);
    }

    public inline function getCapacity(): Int return capacity;

    /**
     * Stores a snapshot at its designated frame index.
     */
    public function saveSnapshot(snapshot: Snapshot): Void {
        var slot = snapshot.frame & mask;
        snapshots[slot] = snapshot.clone();
    }

    /**
     * Retrieves the snapshot matching the frame index, or null if overwritten or unrecorded.
     */
    public function getSnapshot(frame: Int): Snapshot {
        var slot = frame & mask;
        var s = snapshots[slot];
        if (s != null && s.frame == frame) {
            return s;
        }
        return null;
    }

    public function clear(): Void {
        for (i in 0...capacity) {
            snapshots[i] = null;
        }
    }
}
