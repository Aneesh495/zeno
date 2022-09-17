package zeno.spatial;

import haxe.ds.Vector;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPAABB;
import zeno.math.FPMath;
import zeno.geom.Ray;
import zeno.ecs.Entity;

/**
 * Self-balancing Dynamic Bounding Volume Hierarchy (BVH).
 * Implements the Surface Area Heuristic (SAH) for optimal branch selection,
 * rotational rebalancing for logarithmic query depth, and incremental AABB refitting.
 */
class DynamicBVH {
    private var nodes: Vector<BVHNode>;
    private var root: Int;
    private var nodeCapacity: Int;
    private var nodeCount: Int;
    private var freeList: Int;

    public function new(initialCapacity: Int = 128) {
        this.nodeCapacity = initialCapacity > 0 ? initialCapacity : 128;
        this.nodes = new Vector<BVHNode>(nodeCapacity);
        this.root = -1;
        this.nodeCount = 0;

        // Build free list
        for (i in 0...nodeCapacity) {
            nodes[i] = new BVHNode(i);
            nodes[i].parent = (i == nodeCapacity - 1) ? -1 : i + 1;
        }
        this.freeList = 0;
    }

    public inline function getRoot(): Int return root;
    public inline function getNodeCount(): Int return nodeCount;

    /**
     * Allocates a leaf node for an entity with its initial bounding box.
     */
    public function insert(entity: Entity, aabb: FPAABB): Int {
        var nodeId = allocateNode();
        nodes[nodeId].aabb = aabb.clone();
        nodes[nodeId].entity = entity;
        nodes[nodeId].height = 0;

        insertLeaf(nodeId);
        return nodeId;
    }

    /**
     * Removes an entity proxy node from the tree.
     */
    public function remove(nodeId: Int): Void {
        if (nodeId < 0 || nodeId >= nodeCapacity) return;
        removeLeaf(nodeId);
        freeNode(nodeId);
    }

    /**
     * Moves a proxy with motion prediction and fat margin test.
     * @return True if the proxy actually moved outside its fattened AABB and was reinserted.
     */
    public function moveProxy(nodeId: Int, newAABB: FPAABB, displacement: FPVector2): Bool {
        if (nodeId < 0 || nodeId >= nodeCapacity) return false;

        var node = nodes[nodeId];
        // If current fattened AABB already contains new AABB, skip expensive reinsertion
        if (node.aabb.containsAABB(newAABB)) {
            return false;
        }

        removeLeaf(nodeId);

        // Fatten AABB by margin (e.g. 0.1 units)
        var fatAABB = newAABB.clone();
        var margin = FPNumber.fromFloat(0.1);
        fatAABB.expand(margin);

        // Predict movement along displacement vector
        if (displacement != null) {
            var factor = FPNumber.fromInt(2);
            var d = displacement.mul(factor);
            if (d.x < FPNumber.ZERO) {
                fatAABB.lowerBound.x = fatAABB.lowerBound.x + d.x;
            } else {
                fatAABB.upperBound.x = fatAABB.upperBound.x + d.x;
            }
            if (d.y < FPNumber.ZERO) {
                fatAABB.lowerBound.y = fatAABB.lowerBound.y + d.y;
            } else {
                fatAABB.upperBound.y = fatAABB.upperBound.y + d.y;
            }
        }

        node.aabb = fatAABB;
        insertLeaf(nodeId);
        return true;
    }

    public inline function getFatAABB(nodeId: Int): FPAABB {
        return nodes[nodeId].aabb;
    }

    public inline function getEntity(nodeId: Int): Entity {
        return nodes[nodeId].entity;
    }

    /**
     * Queries all leaf nodes whose bounding box overlaps the query AABB.
     */
    public function query(queryAABB: FPAABB, callback: (entity: Entity) -> Bool): Void {
        if (root == -1) return;

        var stack = new Array<Int>();
        stack.push(root);

        while (stack.length > 0) {
            var nodeId = stack.pop();
            var node = nodes[nodeId];

            if (node.aabb.intersects(queryAABB)) {
                if (node.isLeaf()) {
                    var proceed = callback(node.entity);
                    if (!proceed) return;
                } else {
                    stack.push(node.child1);
                    stack.push(node.child2);
                }
            }
        }
    }

    /**
     * Traverses raycast through the dynamic bounding volume tree.
     */
    public function raycast(ray: Ray, callback: (entity: Entity) -> Bool): Void {
        if (root == -1) return;

        var stack = new Array<Int>();
        stack.push(root);

        while (stack.length > 0) {
            var nodeId = stack.pop();
            var node = nodes[nodeId];

            if (node.aabb.raycast(ray.origin, ray.direction, ray.maxDistance)) {
                if (node.isLeaf()) {
                    var proceed = callback(node.entity);
                    if (!proceed) return;
                } else {
                    stack.push(node.child1);
                    stack.push(node.child2);
                }
            }
        }
    }

    private function insertLeaf(leaf: Int): Void {
        if (root == -1) {
            root = leaf;
            nodes[root].parent = -1;
            return;
        }

        // Find the best sibling for the new leaf using Surface Area Heuristic (SAH)
        var leafAABB = nodes[leaf].aabb;
        var index = root;

        while (!nodes[index].isLeaf()) {
            var child1 = nodes[index].child1;
            var child2 = nodes[index].child2;

            var area = nodes[index].aabb.getPerimeter();

            var combinedAABB = new FPAABB();
            combinedAABB.combine(nodes[index].aabb, leafAABB);
            var combinedArea = combinedAABB.getPerimeter();

            // Cost of creating a new parent for this node and the new leaf
            var cost = combinedArea * FPNumber.fromInt(2);
            var inheritanceCost = (combinedArea - area) * FPNumber.fromInt(2);

            // Cost of descending into child1
            var cost1: FPNumber;
            var c1Combined = new FPAABB();
            c1Combined.combine(leafAABB, nodes[child1].aabb);
            if (nodes[child1].isLeaf()) {
                cost1 = c1Combined.getPerimeter() + inheritanceCost;
            } else {
                var oldArea = nodes[child1].aabb.getPerimeter();
                var newArea = c1Combined.getPerimeter();
                cost1 = (newArea - oldArea) + inheritanceCost;
            }

            // Cost of descending into child2
            var cost2: FPNumber;
            var c2Combined = new FPAABB();
            c2Combined.combine(leafAABB, nodes[child2].aabb);
            if (nodes[child2].isLeaf()) {
                cost2 = c2Combined.getPerimeter() + inheritanceCost;
            } else {
                var oldArea = nodes[child2].aabb.getPerimeter();
                var newArea = c2Combined.getPerimeter();
                cost2 = (newArea - oldArea) + inheritanceCost;
            }

            // Descend according to the minimum cost
            if (cost < cost1 && cost < cost2) {
                break;
            }

            if (cost1 < cost2) {
                index = child1;
            } else {
                index = child2;
            }
        }

        var sibling = index;

        // Create a new parent
        var oldParent = nodes[sibling].parent;
        var newParent = allocateNode();
        nodes[newParent].parent = oldParent;
        nodes[newParent].aabb.combine(leafAABB, nodes[sibling].aabb);
        nodes[newParent].height = nodes[sibling].height + 1;

        if (oldParent != -1) {
            // Sibling was not root
            if (nodes[oldParent].child1 == sibling) {
                nodes[oldParent].child1 = newParent;
            } else {
                nodes[oldParent].child2 = newParent;
            }
            nodes[newParent].child1 = sibling;
            nodes[newParent].child2 = leaf;
            nodes[sibling].parent = newParent;
            nodes[leaf].parent = newParent;
        } else {
            // Sibling was root
            nodes[newParent].child1 = sibling;
            nodes[newParent].child2 = leaf;
            nodes[sibling].parent = newParent;
            nodes[leaf].parent = newParent;
            root = newParent;
        }

        // Walk back up the tree refitting AABBs and balancing
        index = nodes[leaf].parent;
        while (index != -1) {
            index = balance(index);

            var c1 = nodes[index].child1;
            var c2 = nodes[index].child2;

            nodes[index].height = 1 + Std.int(Math.max(nodes[c1].height, nodes[c2].height));
            nodes[index].aabb.combine(nodes[c1].aabb, nodes[c2].aabb);

            index = nodes[index].parent;
        }
    }

    private function removeLeaf(leaf: Int): Void {
        if (leaf == root) {
            root = -1;
            return;
        }

        var parent = nodes[leaf].parent;
        var grandParent = nodes[parent].parent;
        var sibling = (nodes[parent].child1 == leaf) ? nodes[parent].child2 : nodes[parent].child1;

        if (grandParent != -1) {
            // Destroy parent and connect sibling to grandParent
            if (nodes[grandParent].child1 == parent) {
                nodes[grandParent].child1 = sibling;
            } else {
                nodes[grandParent].child2 = sibling;
            }
            nodes[sibling].parent = grandParent;
            freeNode(parent);

            // Refit AABBs up the tree
            var index = grandParent;
            while (index != -1) {
                index = balance(index);

                var c1 = nodes[index].child1;
                var c2 = nodes[index].child2;

                nodes[index].aabb.combine(nodes[c1].aabb, nodes[c2].aabb);
                nodes[index].height = 1 + Std.int(Math.max(nodes[c1].height, nodes[c2].height));

                index = nodes[index].parent;
            }
        } else {
            root = sibling;
            nodes[sibling].parent = -1;
            freeNode(parent);
        }
    }

    /**
     * Rebalances subtree around a node using AVL-style rotations.
     */
    private function balance(iA: Int): Int {
        var A = nodes[iA];
        if (A.isLeaf() || A.height < 2) return iA;

        var iB = A.child1;
        var iC = A.child2;
        var B = nodes[iB];
        var C = nodes[iC];

        var balanceFactor = C.height - B.height;

        // Rotate C up
        if (balanceFactor > 1) {
            var iF = C.child1;
            var iG = C.child2;
            var F = nodes[iF];
            var G = nodes[iG];

            // Swap A and C
            C.child1 = iA;
            C.parent = A.parent;
            A.parent = iC;

            // A's old parent points to C
            if (C.parent != -1) {
                if (nodes[C.parent].child1 == iA) {
                    nodes[C.parent].child1 = iC;
                } else {
                    nodes[C.parent].child2 = iC;
                }
            } else {
                root = iC;
            }

            // Rotate
            if (F.height > G.height) {
                C.child2 = iF;
                A.child2 = iG;
                G.parent = iA;
                A.aabb.combine(B.aabb, G.aabb);
                C.aabb.combine(A.aabb, F.aabb);

                A.height = 1 + Std.int(Math.max(B.height, G.height));
                C.height = 1 + Std.int(Math.max(A.height, F.height));
            } else {
                C.child2 = iG;
                A.child2 = iF;
                F.parent = iA;
                A.aabb.combine(B.aabb, F.aabb);
                C.aabb.combine(A.aabb, G.aabb);

                A.height = 1 + Std.int(Math.max(B.height, F.height));
                C.height = 1 + Std.int(Math.max(A.height, G.height));
            }
            return iC;
        }

        // Rotate B up
        if (balanceFactor < -1) {
            var iD = B.child1;
            var iE = B.child2;
            var D = nodes[iD];
            var E = nodes[iE];

            B.child1 = iA;
            B.parent = A.parent;
            A.parent = iB;

            if (B.parent != -1) {
                if (nodes[B.parent].child1 == iA) {
                    nodes[B.parent].child1 = iB;
                } else {
                    nodes[B.parent].child2 = iB;
                }
            } else {
                root = iB;
            }

            if (D.height > E.height) {
                B.child2 = iD;
                A.child1 = iE;
                E.parent = iA;
                A.aabb.combine(C.aabb, E.aabb);
                B.aabb.combine(A.aabb, D.aabb);

                A.height = 1 + Std.int(Math.max(C.height, E.height));
                B.height = 1 + Std.int(Math.max(A.height, D.height));
            } else {
                B.child2 = iE;
                A.child1 = iD;
                D.parent = iA;
                A.aabb.combine(C.aabb, D.aabb);
                B.aabb.combine(A.aabb, E.aabb);

                A.height = 1 + Std.int(Math.max(C.height, D.height));
                B.height = 1 + Std.int(Math.max(A.height, E.height));
            }
            return iB;
        }

        return iA;
    }

    private function allocateNode(): Int {
        if (freeList == -1) {
            // Expand pool
            var oldCap = nodeCapacity;
            var newCap = nodeCapacity << 1;
            var newNodes = new Vector<BVHNode>(newCap);

            for (i in 0...oldCap) {
                newNodes[i] = nodes[i];
            }
            for (i in oldCap...newCap) {
                newNodes[i] = new BVHNode(i);
                newNodes[i].parent = (i == newCap - 1) ? -1 : i + 1;
            }

            this.freeList = oldCap;
            this.nodes = newNodes;
            this.nodeCapacity = newCap;
        }

        var nodeId = freeList;
        freeList = nodes[nodeId].parent;
        nodes[nodeId].reset();
        nodeCount++;
        return nodeId;
    }

    private function freeNode(nodeId: Int): Void {
        nodes[nodeId].parent = freeList;
        nodes[nodeId].height = -1;
        freeList = nodeId;
        nodeCount--;
    }
}
