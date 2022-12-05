package zeno.ecs;

import zeno.Assert;
import zeno.ecs.World;
import zeno.ecs.ComponentType;
import zeno.ecs.Query;

/**
 * Unit test suite for archetype query filtering and iteration.
 */
class TestQuery {
    public static function run(): Void {
        Assert.suite("ECS Query Filtering & Traversal");

        var world = new World(64);
        var tagA = ComponentType.register("TagA", 4);
        var tagB = ComponentType.register("TagB", 4);
        var tagC = ComponentType.register("TagC", 4);

        // e1 has A
        var e1 = world.createEntity();
        world.addComponent(e1, tagA, true);

        // e2 has A and B
        var e2 = world.createEntity();
        world.addComponent(e2, tagA, true);
        world.addComponent(e2, tagB, true);

        // e3 has A, B, and C
        var e3 = world.createEntity();
        world.addComponent(e3, tagA, true);
        world.addComponent(e3, tagB, true);
        world.addComponent(e3, tagC, true);

        // Query 1: with(tagA) -> should match e1, e2, e3
        var q1 = new Query().with(tagA);
        world.registerQuery(q1);
        Assert.equals(3, q1.countEntities(), "Query with(TagA) should match 3 entities");

        // Query 2: with(tagA).with(tagB) -> should match e2, e3
        var q2 = new Query().with(tagA).with(tagB);
        world.registerQuery(q2);
        Assert.equals(2, q2.countEntities(), "Query with(TagA, TagB) should match 2 entities");

        // Query 3: with(tagA).without(tagC) -> should match e1, e2
        var q3 = new Query().with(tagA).without(tagC);
        world.registerQuery(q3);
        Assert.equals(2, q3.countEntities(), "Query with(TagA).without(TagC) should match 2 entities");

        // Query iteration test
        var visited = new Array<Entity>();
        q2.forEach(function(ent, chunk, row) {
            visited.push(ent);
        });
        Assert.equals(2, visited.length, "forEach should visit exactly 2 entities for q2");
        Assert.isTrue(visited.indexOf(e2) >= 0, "q2 iteration should include e2");
        Assert.isTrue(visited.indexOf(e3) >= 0, "q2 iteration should include e3");
        Assert.isFalse(visited.indexOf(e1) >= 0, "q2 iteration should not include e1");
    }
}
