package zeno.ecs;

import zeno.Assert;
import zeno.ecs.Entity;
import zeno.ecs.EntityManager;
import zeno.ecs.ArchetypeGraph;
import zeno.ecs.ComponentType;

/**
 * Unit test suite for generational entity management and archetype transitions.
 */
class TestEntityManager {
    public static function run(): Void {
        Assert.suite("EntityManager Generational Recycling & Transitions");

        var graph = new ArchetypeGraph();
        var em = new EntityManager(graph, 16);

        // Spawn entities
        var e1 = em.createEntity();
        var e2 = em.createEntity();

        Assert.isTrue(em.isAlive(e1), "e1 should be alive");
        Assert.isTrue(em.isAlive(e2), "e2 should be alive");
        Assert.equals(2, em.getActiveCount(), "Active entity count should be 2");
        Assert.isTrue(e1 != e2, "Entity handles should be unique");

        // Destroy entity and verify generation increment (preventing ABA reuse)
        var oldGen = e1.getGeneration();
        var oldIdx = e1.getIndex();
        var destroyed = em.destroyEntity(e1);

        Assert.isTrue(destroyed, "destroyEntity should return true");
        Assert.isFalse(em.isAlive(e1), "Destroyed entity e1 should no longer be alive");
        Assert.equals(1, em.getActiveCount(), "Active entity count should now be 1");

        // Spawn new entity: it should recycle the free index but with an INCREMENTED generation
        var e3 = em.createEntity();
        Assert.equals(oldIdx, e3.getIndex(), "Recycled entity e3 should reuse index of destroyed e1");
        Assert.isTrue(e3.getGeneration() > oldGen, "Recycled entity e3 generation must be greater than oldGen");
        Assert.isFalse(em.isAlive(e1), "Stale handle e1 must NOT be recognized as alive after index recycling");
        Assert.isTrue(em.isAlive(e3), "e3 handle must be recognized as alive");

        // Component insertion and retrieval
        var posType = ComponentType.register("Position", 16);
        em.addComponent(e3, posType, {x: 10, y: 20});
        Assert.isTrue(em.hasComponent(e3, posType), "e3 should have Position component");

        var posVal: Dynamic = em.getComponent(e3, posType);
        Assert.equals(10, posVal.x, "Position.x should be 10");
        Assert.equals(20, posVal.y, "Position.y should be 20");

        // Component removal
        em.removeComponent(e3, posType);
        Assert.isFalse(em.hasComponent(e3, posType), "e3 should no longer have Position component after removal");
    }
}
