package zeno.replay;

import haxe.io.Bytes;
import zeno.core.Buffer;

/**
 * Metadata container for recorded simulation replays.
 */
class ReplayHeader {
    public static var MAGIC: String = "ZENO_REPLAY";
    public static var VERSION: Int = 1;

    public var magic: String;
    public var version: Int;
    public var initialSeed: Int;
    public var playerCount: Int;
    public var tickRateHz: Int;
    public var totalFrames: Int;

    public function new(seed: Int = 42, players: Int = 2, tickRate: Int = 60) {
        this.magic = MAGIC;
        this.version = VERSION;
        this.initialSeed = seed;
        this.playerCount = players;
        this.tickRateHz = tickRate;
        this.totalFrames = 0;
    }

    public function serialize(): Buffer {
        var buf = new Buffer(64);
        buf.writeString(magic);
        buf.writeInt32(version);
        buf.writeInt32(initialSeed);
        buf.writeInt32(playerCount);
        buf.writeInt32(tickRateHz);
        buf.writeInt32(totalFrames);
        return buf;
    }

    public static function deserialize(buf: Buffer): ReplayHeader {
        var magic = buf.readString();
        if (magic != MAGIC) return null;

        var h = new ReplayHeader();
        h.version = buf.readInt32();
        h.initialSeed = buf.readInt32();
        h.playerCount = buf.readInt32();
        h.tickRateHz = buf.readInt32();
        h.totalFrames = buf.readInt32();
        return h;
    }
}
