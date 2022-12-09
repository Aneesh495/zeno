package zeno.spatial;

import zeno.Assert;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPAABB;
import zeno.spatial.DynamicBVH;
import zeno.ecs.Entity;
import zeno.geom.Ray;

/**
 * Unit test suite for Dynamic Bounding Volume Hierarchy (BVH).
 */
class TestDynamicBVH {
    public static function run(): Void {
        Assert.suite("Dynamic Bounding Volume Hierarchy (BVH)");

        var bvh = new DynamicBVH(64);
        var e1 = Entity.make(1, 1);
        var e2 = Entity.make(2, 1);
        var e3 = Entity.make(3, 1);

        // Insert proxies
        var aabb1 = FPAABB.make(FPNumber.fromInt(0), FPNumber.fromInt(0), FPNumber.fromInt(2), FPNumber.fromInt(2));
        var aabb2 = FPAABB.make(FPNumber.fromInt(5), FPNumber.fromInt(0), FPNumber.fromInt(7), FPNumber.fromInt(2));
        var aabb3 = FPAABB.make(FPNumber.fromInt(10), FPNumber.fromInt(0), FPNumber.fromInt(12), FPNumber.fromInt(2));

        var p1 = bvh.insert(e1, aabb1);
        var p2 = bvh.insert(e2, aabb2);
        var p3 = bvh.insert(e3, aabb3);

        Assert.equals(5, bvh.getNodeCount(), "BVH total node count (3 leaves + 2 branch nodes) should be 5");

        // Spatial query overlapping only proxy 1
        var queryAABB1 = FPAABB.make(FPNumber.fromInt(1), FPNumber.fromInt(1), FPNumber.fromInt(3), FPNumber.fromInt(3));
        var hits1 = new Array<Entity>();
        bvh.query(queryAABB1, function(ent) {
            hits1.push(ent);
            return true;
        });

        Assert.equals(1, hits1.length, "queryAABB1 should match exactly 1 entity");
        Assert.equals(e1.getRaw(), hits1[0].getRaw(), "queryAABB1 should match e1");

        // Spatial query enclosing all three proxies
        var queryAll = FPAABB.make(FPNumber.fromInt(-1), FPNumber.fromInt(-1), FPNumber.fromInt(15), FPNumber.fromInt(5));
        var hitsAll = new Array<Entity>();
        bvh.query(queryAll, function(ent) {
            hitsAll.push(ent);
            return true;
        });

        Assert.equals(3, hitsAll.length, "queryAll should match all 3 entities");

        // Raycast test: ray along X-axis at Y=1 from X=-5 to X=20
        var ray = new Ray(new FPVector2(FPNumber.fromInt(-5), FPNumber.ONE), FPVector2.RIGHT, FPNumber.fromInt(25));
        var rayHits = new Array<Entity>();
        bvh.raycast(ray, function(ent) {
            rayHits.push(ent);
            return true;
        });

        Assert.equals(3, rayHits.length, "Ray penetrating all three boxes should record 3 hits");

        // Remove proxy
        bvh.remove(p2);
        var hitsAfterRemove = new Array<Entity>();
        bvh.query(queryAll, function(ent) {
            hitsAfterRemove.push(ent);
            return true;
        });

        Assert.equals(2, hitsAfterRemove.length, "After removing p2, query should match exactly 2 entities");
        Assert.isFalse(hitsAfterRemove.indexOf(e2) >= 0, "e2 should no longer be in query results");
    }
}
