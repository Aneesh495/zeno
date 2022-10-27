package zeno.net;

import haxe.io.Bytes;
import zeno.core.Buffer;
import zeno.core.CRC32C;
import zeno.rollback.Snapshot;

enum StateSyncType {
    SyncFull;
    SyncDelta;
}

/**
 * State synchronization packet for state replication and late-joiner synchronization.
 */
class StateSyncPacket {
    public var type: StateSyncType;
    public var frame: Int;
    public var baselineFrame: Int; // Frame against which delta is computed
    public var payload: Bytes;

    public function new(type: StateSyncType, frame: Int, payload: Bytes, baselineFrame: Int = 0) {
        this.type = type;
        this.frame = frame;
        this.payload = payload;
        this.baselineFrame = baselineFrame;
    }

    public function serialize(): Buffer {
        var buf = new Buffer(64 + payload.length);
        buf.writeByte(type == SyncFull ? 0 : 1);
        buf.writeInt32(frame);
        buf.writeInt32(baselineFrame);
        buf.writeInt32(payload.length);
        buf.writeBytes(payload, 0, payload.length);

        var checksum = CRC32C.compute(buf.toBytes());
        buf.writeInt32(checksum);
        return buf;
    }

    public static function deserialize(buf: Buffer): StateSyncPacket {
        buf.setReadPosition(0);
        var typeByte = buf.readByte();
        var type = (typeByte == 0) ? SyncFull : SyncDelta;
        var frame = buf.readInt32();
        var baseFrame = buf.readInt32();
        var len = buf.readInt32();
        var payload = buf.readBytes(len);

        var payloadLen = buf.getReadPosition();
        var readChecksum = buf.readInt32();
        var calculatedChecksum = CRC32C.compute(buf.getRawBytes(), 0, payloadLen);

        if (readChecksum != calculatedChecksum) {
            return null;
        }

        return new StateSyncPacket(type, frame, payload, baseFrame);
    }
}
