package zeno.core;

import haxe.io.Bytes;

/**
 * Linear bump-pointer memory arena for transient per-frame allocations.
 * Enables O(1) bulk deallocation by simply rewinding the allocation pointer,
 * avoiding heap allocations and GC pressure during collision and constraint solving.
 */
class MemoryArena {
    private var buffer: Bytes;
    private var capacity: Int;
    private var offset: Int;
    private var mark: Int;

    public function new(initialCapacity: Int = 65536) {
        this.capacity = initialCapacity > 0 ? initialCapacity : 65536;
        this.buffer = Bytes.alloc(this.capacity);
        this.offset = 0;
        this.mark = 0;
    }

    public inline function getCapacity(): Int return capacity;
    public inline function getUsedBytes(): Int return offset;
    public inline function getRemainingBytes(): Int return capacity - offset;

    /**
     * Bumps the allocation pointer by size bytes with 8-byte alignment.
     * @param size Number of bytes requested.
     * @return Byte offset into internal buffer where allocation begins.
     */
    public function allocate(size: Int): Int {
        // Enforce 8-byte alignment
        var alignedOffset = (offset + 7) & ~7;
        var end = alignedOffset + size;

        if (end > capacity) {
            // Expand arena buffer
            var newCap = capacity;
            while (newCap < end) {
                newCap = newCap << 1;
            }
            var newBuf = Bytes.alloc(newCap);
            newBuf.blit(0, buffer, 0, offset);
            this.buffer = newBuf;
            this.capacity = newCap;
        }

        this.offset = end;
        return alignedOffset;
    }

    /**
     * Saves the current allocation offset as a bookmark.
     */
    public inline function saveMark(): Int {
        this.mark = offset;
        return mark;
    }

    /**
     * Rewinds the allocation offset to a previously saved bookmark.
     */
    public inline function restoreMark(savedMark: Int): Void {
        if (savedMark >= 0 && savedMark <= offset) {
            this.offset = savedMark;
        }
    }

    /**
     * Completely resets the arena to 0 allocated bytes.
     */
    public inline function reset(): Void {
        this.offset = 0;
        this.mark = 0;
    }

    public inline function getBuffer(): Bytes {
        return buffer;
    }
}
