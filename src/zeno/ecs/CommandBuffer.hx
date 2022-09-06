package zeno.ecs;

enum CommandOp {
    OpDestroy(entity: Entity);
    OpAddComponent(entity: Entity, componentType: ComponentType, value: Dynamic);
    OpRemoveComponent(entity: Entity, componentType: ComponentType);
    OpSetComponent(entity: Entity, componentType: ComponentType, value: Dynamic);
}

/**
 * Command buffer for deferred structural entity mutations.
 * Allows systems to schedule entity creation, destruction, and component
 * changes safely during iteration without invalidating query arrays.
 */
class CommandBuffer {
    private var commands: Array<CommandOp>;

    public function new() {
        this.commands = new Array<CommandOp>();
    }

    public inline function destroyEntity(entity: Entity): Void {
        commands.push(OpDestroy(entity));
    }

    public inline function addComponent(entity: Entity, componentType: ComponentType, value: Dynamic): Void {
        commands.push(OpAddComponent(entity, componentType, value));
    }

    public inline function removeComponent(entity: Entity, componentType: ComponentType): Void {
        commands.push(OpRemoveComponent(entity, componentType));
    }

    public inline function setComponent(entity: Entity, componentType: ComponentType, value: Dynamic): Void {
        commands.push(OpSetComponent(entity, componentType, value));
    }

    /**
     * Executes all queued commands against the target world and clears the buffer.
     */
    public function flush(world: World): Void {
        var len = commands.length;
        for (i in 0...len) {
            switch (commands[i]) {
                case OpDestroy(entity):
                    world.getEntityManager().destroyEntity(entity);
                case OpAddComponent(entity, ct, value):
                    world.getEntityManager().addComponent(entity, ct, value);
                case OpRemoveComponent(entity, ct):
                    world.getEntityManager().removeComponent(entity, ct);
                case OpSetComponent(entity, ct, value):
                    world.getEntityManager().setComponent(entity, ct, value);
            }
        }
        while (commands.length > 0) {
            commands.pop();
        }
    }

    public inline function getPendingCount(): Int {
        return commands.length;
    }

    public inline function clear(): Void {
        while (commands.length > 0) {
            commands.pop();
        }
    }
}
