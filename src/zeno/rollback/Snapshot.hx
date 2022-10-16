package zeno.rollback;

import haxe.io.Bytes;
import zeno.core.Buffer;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.ecs.Entity;

/**
 * Serializable state record for an individual entity.
 */
class EntityStateRecord {
    public var entity: Entity;
    public var posX: FPNumber;
    public var posY: FPNumber;
    public var angle: FPNumber;
    public var velX: FPNumber;
    public var velY: FPNumber;
    public var angVel: FPNumber;
    public var isAwake: Bool;

    public function new(ent: Entity) {
        this.entity = ent;
        this.posX = FPNumber.ZERO;
        this.posY = FPNumber.ZERO;
        this.angle = FPNumber.ZERO;
        this.velX = FPNumber.ZERO;
        this.velY = FPNumber.ZERO;
        this.angVel = FPNumber.ZERO;
        this.isAwake = true;
    }
}

/**
 * Complete immutable snapshot of the simulation world state at a specific tick.
 * Encapsulates PRNG state, entity kinematics, and contact impulses.
 */
class Snapshot {
    public var frame: Int;
    public var rngStateHigh: Int;
    public var rngStateLow: Int;
    public var entities: Array<EntityStateRecord>;
    public var checksum: Int;

    public function new(frame: Int = 0) {
        this.frame = frame;
        this.rngStateHigh = 0;
        this.rngStateLow = 0;
        this.entities = new Array<EntityStateRecord>();
        this.checksum = 0;
    }

    public function addEntityState(
        ent: Entity,
        pos: FPVector2,
        angle: FPNumber,
        vel: FPVector2,
        angVel: FPNumber,
        isAwake: Bool
    ): Void {
        var rec = new EntityStateRecord(ent);
        rec.posX = pos.x;
        rec.posY = pos.y;
        rec.angle = angle;
        rec.velX = vel.x;
        rec.velY = vel.y;
        rec.angVel = angVel;
        rec.isAwake = isAwake;
        entities.push(rec);
    }

    /**
     * Serializes this snapshot into a contiguous deterministic binary buffer.
     */
    public function serialize(): Buffer {
        var buf = new Buffer(64 + (entities.length * 32));
        buf.writeInt32(frame);
        buf.writeInt32(rngStateHigh);
        buf.writeInt32(rngStateLow);
        buf.writeInt32(entities.length);

        var len = entities.length;
        for (i in 0...len) {
            var e = entities[i];
            buf.writeInt32(e.entity.getRaw());
            buf.writeInt32(e.posX.getRaw());
            buf.writeInt32(e.posY.getRaw());
            buf.writeInt32(e.angle.getRaw());
            buf.writeInt32(e.velX.getRaw());
            buf.writeInt32(e.velY.getRaw());
            buf.writeInt32(e.angVel.getRaw());
            buf.writeBool(e.isAwake);
        }

        return buf;
    }

    /**
     * Deserializes a snapshot from a binary buffer.
     */
    public static function deserialize(buf: Buffer): Snapshot {
        var s = new Snapshot(buf.readInt32());
        s.rngStateHigh = buf.readInt32();
        s.rngStateLow = buf.readInt32();

        var count = buf.readInt32();
        for (i in 0...count) {
            var ent = new Entity(buf.readInt32());
            var rec = new EntityStateRecord(ent);
            rec.posX = FPNumber.fromRaw(buf.readInt32());
            rec.posY = FPNumber.fromRaw(buf.readInt32());
            rec.angle = FPNumber.fromRaw(buf.readInt32());
            rec.velX = FPNumber.fromRaw(buf.readInt32());
            rec.velY = FPNumber.fromRaw(buf.readInt32());
            rec.angVel = FPNumber.fromRaw(buf.readInt32());
            rec.isAwake = buf.readBool();
            s.entities.push(rec);
        }

        return s;
    }

    public function clone(): Snapshot {
        var c = new Snapshot(frame);
        c.rngStateHigh = rngStateHigh;
        c.rngStateLow = rngStateLow;
        c.checksum = checksum;
        for (e in entities) {
            var rec = new EntityStateRecord(e.entity);
            rec.posX = e.posX;
            rec.posY = e.posY;
            rec.angle = e.angle;
            rec.velX = e.velX;
            rec.velY = e.velY;
            rec.angVel = e.angVel;
            rec.isAwake = e.isAwake;
            c.entities.push(rec);
        }
        return c;
    }
}
