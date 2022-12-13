package zeno.replay;

import zeno.Assert;
import zeno.replay.ReplayStream;
import zeno.replay.ReplayReader;
import zeno.replay.ReplayVerifier;

/**
 * Unit test suite for binary simulation replay recording and bit-exact verification.
 */
class TestReplayStream {
    public static function run(): Void {
        Assert.suite("Binary Replay Stream & Verification");

        var stream = new ReplayStream(1337, 2, 60);

        // Record 10 frames
        for (f in 0...10) {
            var inputs = [f * 2, f * 3];
            var hash = (f % 5 == 0) ? (0xABCD0000 + f) : 0;
            stream.recordFrame(f, inputs, hash);
        }

        Assert.equals(10, stream.getFrameCount(), "Recorded frame count should be 10");

        // Serialize to binary buffer and deserialize with reader
        var buf = stream.serialize();
        var reader = new ReplayReader(buf);

        Assert.equals("ZENO_REPLAY", reader.header.magic, "Replay magic header must match");
        Assert.equals(1337, reader.header.initialSeed, "Replay initial seed must match");
        Assert.equals(10, reader.getFrameCount(), "Deserialized frame count must match");
        Assert.equals(8, reader.getInput(4, 0), "Frame 4 player 0 input should be 8");
        Assert.equals(12, reader.getInput(4, 1), "Frame 4 player 1 input should be 12");
        Assert.equals(0xABCD0005, reader.getCheckpointHash(5), "Frame 5 checkpoint hash must match");

        // Verification test: matching simulation returns identical hashes
        var verifyRes = ReplayVerifier.verify(reader, function(frame: Int, inputs: Array<Int>): Int {
            return (frame % 5 == 0) ? (0xABCD0000 + frame) : 0;
        });

        Assert.isTrue(verifyRes.isValid, "Replay verification must pass when state hashes match");
        Assert.equals(2, verifyRes.totalChecked, "Should have verified 2 checkpoints (frames 0 and 5)");
    }
}
