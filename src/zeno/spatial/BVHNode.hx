package zeno.spatial;

import zeno.math.FPAABB;
import zeno.ecs.Entity;

/**
 * Node within the Dynamic Bounding Volume Hierarchy (BVH) tree.
 * Can be either a leaf node holding an entity reference, or an internal branch
 * node enclosing two child subtrees.
 */
class BVHNode {
    public var id: Int;
    public var aabb: FPAABB;
    public var entity: Entity;
    public var parent: Int;
    public var child1: Int;
    public var child2: Int;
    public var height: Int;

    public function new(id: Int) {
        this.id = id;
        this.aabb = new FPAABB();
        this.entity = Entity.NONE;
        this.parent = -1;
        this.child1 = -1;
        this.child2 = -1;
        this.height = 0;
    }

    public inline function isLeaf(): Bool {
        return child1 == -1;
    }

    public function reset(): Void {
        this.entity = Entity.NONE;
        this.parent = -1;
        this.child1 = -1;
        this.child2 = -1;
        this.height = 0;
    }
}
