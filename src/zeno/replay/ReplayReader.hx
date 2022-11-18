package zeno.replay;

import zeno.core.Buffer;
import zeno.replay.ReplayStream.ReplayFrameRecord;

/**
 * Binary replay reader and seeker.
 */
class ReplayReader {
    public var header(default, null): ReplayHeader;
    public var frames(default, null): Array<ReplayFrameRecord>;

    public function new(buf: Buffer) {
        this.frames = new Array<ReplayFrameRecord>();
        parse(buf);
    }

    private function parse(buf: Buffer): Void {
        this.header = ReplayHeader.deserialize(buf);
        if (header == null) return;

        var numFrames = buf.readInt32();
        for (i in 0...numFrames) {
            var frame = buf.readInt32();
            var hash = buf.readInt32();
            var numInps = buf.readByte();
            var inps = new Array<Int>();
            for (p in 0...numInps) {
                inps.push(buf.readInt32());
            }
            frames.push(new ReplayFrameRecord(frame, inps, hash));
        }
    }

    public inline function getFrameCount(): Int return frames.length;

    public function getInput(frame: Int, player: Int): Int {
        if (frame >= 0 && frame < frames.length) {
            var rec = frames[frame];
            if (player >= 0 && player < rec.inputs.length) {
                return rec.inputs[player];
            }
        }
        return 0;
    }

    public function getCheckpointHash(frame: Int): Int {
        if (frame >= 0 && frame < frames.length) {
            return frames[frame].checkpointHash;
        }
        return 0;
    }
}
