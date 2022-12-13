package zeno.net;

import zeno.Assert;
import zeno.net.InputPacket;
import zeno.net.JitterBuffer;

/**
 * Unit test suite for network jitter buffer, packet loss recovery, and packet reordering.
 */
class TestJitterBuffer {
    public static function run(): Void {
        Assert.suite("Network Jitter Buffer & Loss Healing");

        var jb = new JitterBuffer();

        // Packet 1 for Frame 0 (seq 1, input 0x01)
        var p1 = new InputPacket(1, 0, 0x01, [0, 0, 0]);
        jb.pushPacket(p1);
        Assert.isTrue(jb.hasFrame(0), "Jitter buffer should contain Frame 0");
        Assert.equals(0x01, jb.getFrameInput(0), "Frame 0 input should match 0x01");

        // Simulate packet loss: Packet for Frame 1 is DROPPED!
        // Packet 3 arrives for Frame 2 carrying trailing inputs: [Frame 1 input = 0x02, Frame 0 input = 0x01]
        var p3 = new InputPacket(3, 2, 0x04, [0x02, 0x01, 0x00]);
        jb.pushPacket(p3);

        Assert.isTrue(jb.hasFrame(2), "Jitter buffer should contain Frame 2");
        Assert.equals(0x04, jb.getFrameInput(2), "Frame 2 input should match 0x04");

        // The dropped packet for Frame 1 should have been automatically healed and recovered!
        Assert.isTrue(jb.hasFrame(1), "Dropped Frame 1 must be recovered from trailing redundant inputs");
        Assert.equals(0x02, jb.getFrameInput(1), "Recovered Frame 1 input must match trailing payload 0x02");
    }
}
