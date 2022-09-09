package zeno.ecs;

import zeno.math.FPNumber;
import zeno.ecs.System.ISystem;

/**
 * Central ECS World coordinator.
 * Owns the entity manager, archetype graph, registered queries,
 * command buffer, and execution pipeline.
 */
class World {
    private var graph: ArchetypeGraph;
    private var entityManager: EntityManager;
    private var commandBuffer: CommandBuffer;
    private var queries: Array<Query>;
    private var systemPipeline: SystemGroup;
    private var currentTick: Int;

    public function new(initialEntityCapacity: Int = 1024) {
        this.graph = new ArchetypeGraph();
        this.entityManager = new EntityManager(graph, initialEntityCapacity);
        this.commandBuffer = new CommandBuffer();
        this.queries = new Array<Query>();
        this.systemPipeline = new SystemGroup("RootPipeline", 0);
        this.currentTick = 0;
    }

    public inline function getGraph(): ArchetypeGraph return graph;
    public inline function getEntityManager(): EntityManager return entityManager;
    public inline function getCommandBuffer(): CommandBuffer return commandBuffer;
    public inline function getCurrentTick(): Int return currentTick;

    public inline function createEntity(?initialArchetype: Archetype, ?initialComponents: Array<Dynamic>): Entity {
        return entityManager.createEntity(initialArchetype, initialComponents);
    }

    public inline function destroyEntity(entity: Entity): Bool {
        return entityManager.destroyEntity(entity);
    }

    public inline function isAlive(entity: Entity): Bool {
        return entityManager.isAlive(entity);
    }

    public inline function addComponent(entity: Entity, componentType: ComponentType, value: Dynamic): Void {
        entityManager.addComponent(entity, componentType, value);
    }

    public inline function removeComponent(entity: Entity, componentType: ComponentType): Void {
        entityManager.removeComponent(entity, componentType);
    }

    public inline function getComponent(entity: Entity, componentType: ComponentType): Dynamic {
        return entityManager.getComponent(entity, componentType);
    }

    public inline function setComponent(entity: Entity, componentType: ComponentType, value: Dynamic): Void {
        entityManager.setComponent(entity, componentType, value);
    }

    public inline function hasComponent(entity: Entity, componentType: ComponentType): Bool {
        return entityManager.hasComponent(entity, componentType);
    }

    public inline function getEntityCount(): Int {
        return entityManager.getActiveCount();
    }

    /**
     * Registers a new query with this world and populates its initial matched archetypes.
     */
    public function registerQuery(query: Query): Query {
        queries.push(query);
        query.updateMatchedArchetypes(graph.getAllArchetypes());
        return query;
    }

    /**
     * Adds an execution system to the world pipeline.
     */
    public function addSystem(system: ISystem): World {
        systemPipeline.addSystem(system);
        system.init(this);
        return this;
    }

    /**
     * Flushes deferred structural commands.
     */
    public function flushCommands(): Void {
        commandBuffer.flush(this);
    }

    /**
     * Advances the world simulation by a fixed time step.
     */
    public function step(dt: FPNumber): Void {
        systemPipeline.update(this, dt);
        flushCommands();
        currentTick++;
    }

    public function clear(): Void {
        systemPipeline.destroy(this);
        commandBuffer.clear();
        entityManager.clear();
        currentTick = 0;
    }
}
