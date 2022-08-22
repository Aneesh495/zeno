package zeno.core;

import haxe.ds.Vector;

/**
 * Fixed-capacity circular ring buffer with power-of-two capacity
 * for fast bitmask indexing without modulo division.
 * Core primitive for input history queues and rollback snapshot frames.
 */
class RingBuffer<T> {
    private var buffer: Vector<T>;
    private var capacity: Int;
    private var mask: Int;
    private var head: Int;
    private var tail: Int;
    private var count: Int;

    public var size(get, never): Int;

    public function new(requestedCapacity: Int = 128) {
        // Enforce power of two
        var cap = 1;
        while (cap < requestedCapacity) {
            cap = cap << 1;
        }
        this.capacity = cap;
        this.mask = cap - 1;
        this.buffer = new Vector<T>(cap);
        this.head = 0;
        this.tail = 0;
        this.count = 0;
    }

    public inline function get_size(): Int return count;
    public inline function getCapacity(): Int return capacity;
    public inline function isFull(): Bool return count >= capacity;
    public inline function isEmpty(): Bool return count == 0;

    /**
     * Appends an element to the tail of the ring buffer.
     * If the buffer is full, overwrites the oldest element at the head.
     * @param item Element to insert.
     * @return True if inserted without overwrite, false if overwrite occurred.
     */
    public function push(item: T): Bool {
        var overwritten = false;
        if (count >= capacity) {
            // Drop oldest item
            head = (head + 1) & mask;
            count -= 1;
            overwritten = true;
        }
        buffer[tail] = item;
        tail = (tail + 1) & mask;
        count += 1;
        return !overwritten;
    }

    /**
     * Removes and returns the oldest element from the head.
     */
    public function pop(): T {
        if (count == 0) return null;
        var item = buffer[head];
        buffer[head] = null;
        head = (head + 1) & mask;
        count -= 1;
        return item;
    }

    /**
     * Peeks at the element at the head (oldest element).
     */
    public function peekHead(): T {
        if (count == 0) return null;
        return buffer[head];
    }

    /**
     * Peeks at the element at the tail (newest inserted element).
     */
    public function peekTail(): T {
        if (count == 0) return null;
        var idx = (tail - 1) & mask;
        return buffer[idx];
    }

    /**
     * Retrieves an element by offset relative to head (0 = oldest).
     */
    public function get(offsetFromHead: Int): T {
        if (offsetFromHead < 0 || offsetFromHead >= count) return null;
        var idx = (head + offsetFromHead) & mask;
        return buffer[idx];
    }

    /**
     * Sets an element by offset relative to head.
     */
    public function set(offsetFromHead: Int, value: T): Void {
        if (offsetFromHead < 0 || offsetFromHead >= count) return;
        var idx = (head + offsetFromHead) & mask;
        buffer[idx] = value;
    }

    public function clear(): Void {
        for (i in 0...capacity) {
            buffer[i] = null;
        }
        head = 0;
        tail = 0;
        count = 0;
    }
}
