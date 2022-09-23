package zeno.spatial;

import haxe.ds.IntMap;
import zeno.math.FPAABB;
import zeno.math.FPVector2;
import zeno.ecs.Entity;

class BroadphasePair {
    public var entityA: Entity;
    public var entityB: Entity;

    public function new(a: Entity, b: Entity) {
        // Enforce canonical order: lower entity ID first
        if (a.getRaw() < b.getRaw()) {
            this.entityA = a;
            this.entityB = b;
        } else {
            this.entityA = b;
            this.entityB = a;
        }
    }

    public inline function equals(other: BroadphasePair): Bool {
        return this.entityA == other.entityA && this.entityB == other.entityB;
    }
}

/**
 * Broadphase collision acceleration coordinator.
 * Maintains the Dynamic BVH tree, buffers moved proxies, and
 * generates candidate collision pairs for narrowphase evaluation.
 */
class Broadphase {
    private var tree: DynamicBVH;
    private var proxyCount: Int;
    private var moveBuffer: Array<Int>;
    private var entityToProxy: IntMap<Int>;

    public function new() {
        this.tree = new DynamicBVH(256);
        this.proxyCount = 0;
        this.moveBuffer = new Array<Int>();
        this.entityToProxy = new IntMap<Int>();
    }

    public inline function getTree(): DynamicBVH return tree;
    public inline function getProxyCount(): Int return proxyCount;

    /**
     * Registers an entity bounding volume proxy in the broadphase tree.
     */
    public function createProxy(entity: Entity, aabb: FPAABB): Int {
        var proxyId = tree.insert(entity, aabb);
        entityToProxy.set(entity.getIndex(), proxyId);
        bufferMove(proxyId);
        proxyCount++;
        return proxyId;
    }

    /**
     * Removes an entity proxy from the broadphase tree.
     */
    public function destroyProxy(entity: Entity): Void {
        var idx = entity.getIndex();
        var proxyId = entityToProxy.get(idx);
        if (proxyId != null) {
            tree.remove(proxyId);
            entityToProxy.remove(idx);
            var bufIdx = moveBuffer.indexOf(proxyId);
            if (bufIdx >= 0) moveBuffer.splice(bufIdx, 1);
            proxyCount--;
        }
    }

    /**
     * Updates proxy location with motion displacement.
     */
    public function moveProxy(entity: Entity, aabb: FPAABB, displacement: FPVector2): Void {
        var proxyId = entityToProxy.get(entity.getIndex());
        if (proxyId != null) {
            var moved = tree.moveProxy(proxyId, aabb, displacement);
            if (moved) {
                bufferMove(proxyId);
            }
        }
    }

    /**
     * Computes all potential overlapping candidate collision pairs.
     * Iterates only over moved proxies against the static/dynamic tree.
     */
    public function computePairs(callback: (entityA: Entity, entityB: Entity) -> Void): Void {
        var len = moveBuffer.length;
        for (i in 0...len) {
            var proxyId = moveBuffer[i];
            var queryEntity = tree.getEntity(proxyId);
            var fatAABB = tree.getFatAABB(proxyId);

            tree.query(fatAABB, function(otherEntity: Entity): Bool {
                // Ignore self collision
                if (queryEntity == otherEntity) return true;

                // Enforce canonical pair emission to prevent duplicate checks
                if (queryEntity.getRaw() < otherEntity.getRaw()) {
                    callback(queryEntity, otherEntity);
                } else {
                    callback(otherEntity, queryEntity);
                }
                return true;
            });
        }

        // Clear move buffer
        while (moveBuffer.length > 0) moveBuffer.pop();
    }

    private inline function bufferMove(proxyId: Int): Void {
        if (moveBuffer.indexOf(proxyId) < 0) {
            moveBuffer.push(proxyId);
        }
    }

    public function clear(): Void {
        tree = new DynamicBVH(256);
        while (moveBuffer.length > 0) moveBuffer.pop();
        entityToProxy = new IntMap<Int>();
        proxyCount = 0;
    }
}
