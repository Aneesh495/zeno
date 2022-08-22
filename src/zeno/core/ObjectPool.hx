package zeno.core;

/**
 * Generic object pool designed to eliminate per-frame garbage collector allocations.
 * Objects are allocated once and recycled back into the pool upon release.
 */
class ObjectPool<T> {
    private var pool: Array<T>;
    private var factory: Void -> T;
    private var resetCallback: T -> Void;
    private var allocatedCount: Int;

    public function new(factory: Void -> T, ?resetCallback: T -> Void, initialSize: Int = 32) {
        this.factory = factory;
        this.resetCallback = resetCallback;
        this.pool = new Array<T>();
        this.allocatedCount = 0;

        for (i in 0...initialSize) {
            pool.push(factory());
            allocatedCount++;
        }
    }

    /**
     * Obtains an instance from the pool, or instantiates a new one if empty.
     */
    public function acquire(): T {
        if (pool.length > 0) {
            return pool.pop();
        }
        allocatedCount++;
        return factory();
    }

    /**
     * Returns an instance back to the pool, invoking the optional reset callback.
     */
    public function release(instance: T): Void {
        if (instance == null) return;
        if (resetCallback != null) {
            resetCallback(instance);
        }
        pool.push(instance);
    }

    public inline function getAvailableCount(): Int return pool.length;
    public inline function getTotalAllocated(): Int return allocatedCount;

    public function clear(): Void {
        while (pool.length > 0) {
            pool.pop();
        }
    }
}
