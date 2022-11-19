package zeno.event;

import zeno.ecs.Entity;
import zeno.math.FPVector2;

enum SimulationEvent {
    EventCollisionEnter(entityA: Entity, entityB: Entity, normal: FPVector2, point: FPVector2);
    EventCollisionExit(entityA: Entity, entityB: Entity);
    EventDesyncDetected(frame: Int, localHash: Int, remoteHash: Int);
    EventRollbackExecuted(fromFrame: Int, toFrame: Int, resimulatedCount: Int);
    EventEntitySpawned(entity: Entity);
    EventEntityDestroyed(entity: Entity);
}
