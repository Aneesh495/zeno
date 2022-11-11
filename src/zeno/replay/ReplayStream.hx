package zeno.replay;

import haxe.io.Bytes;
import zeno.core.Buffer;

class ReplayFrameRecord {
    public var frame: Int;
    public var inputs: Array<Int>;
    public var checkpointHash: Int; // Optional periodic checksum (0 if none)

    public function new(frame: Int, inputs: Array<Int>, hash: Int = 0) {
        this.frame = frame;
        this.inputs = inputs.copy();
        this.checkpointHash = hash;
    }
}

/**
 * Compact binary simulation replay stream recorder.
 */
class ReplayStream {
    public var header: ReplayHeader;
    private var frames: Array<ReplayFrameRecord>;

    public function new(seed: Int = 42, players: Int = 2, tickRate: Int = 60) {
        this.header = new ReplayHeader(seed, players, tickRate);
        this.frames = new Array<ReplayFrameRecord>();
    }

    public function recordFrame(frame: Int, playerInputs: Array<Int>, checkpointHash: Int = 0): Void {
        frames.push(new ReplayFrameRecord(frame, playerInputs, checkpointHash));
        header.totalFrames = frames.length;
    }

    public function serialize(): Buffer {
        var headerBuf = header.serialize();
        var buf = new Buffer(headerBuf.getWritePosition() + (frames.length * 16));
        buf.writeBytes(headerBuf.toBytes(), 0, headerBuf.getWritePosition());

        buf.writeInt32(frames.length);
        for (f in frames) {
            buf.writeInt32(f.frame);
            buf.writeInt32(f.checkpointHash);
            buf.writeByte(f.inputs.length);
            for (inp in f.inputs) {
                buf.writeInt32(inp);
            }
        }

        return buf;
    }

    public inline function getFrameCount(): Int return frames.length;
    public inline function getFrame(index: Int): ReplayFrameRecord return frames[index];
}
