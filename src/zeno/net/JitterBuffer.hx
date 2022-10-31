package zeno.net;

import haxe.ds.IntMap;

/**
 * Adaptive sliding-window jitter buffer.
 * Reorders out-of-order UDP datagrams, extracts redundant trailing inputs
 * from subsequent packets to heal packet loss, and suppresses duplicate frames.
 */
class JitterBuffer {
    private var buffer: IntMap<Int>; // frame -> inputBits
    private var highestReceivedFrame: Int;
    private var lowestBufferedFrame: Int;

    public function new() {
        this.buffer = new IntMap<Int>();
        this.highestReceivedFrame = -1;
        this.lowestBufferedFrame = 0;
    }

    public inline function getHighestReceivedFrame(): Int return highestReceivedFrame;

    /**
     * Ingests an incoming packet, extracting current input and trailing redundant inputs.
     */
    public function pushPacket(packet: InputPacket): Void {
        if (packet == null) return;

        // Current frame input
        storeInput(packet.targetFrame, packet.currentInput);

        // Extract redundant trailing inputs: packet.pastInputs[0] is F-1, [1] is F-2, [2] is F-3
        for (i in 0...packet.pastInputs.length) {
            var trailingFrame = packet.targetFrame - (i + 1);
            if (trailingFrame >= 0 && !buffer.exists(trailingFrame)) {
                storeInput(trailingFrame, packet.pastInputs[i]);
            }
        }
    }

    /**
     * Checks if input for frame is ready in the buffer.
     */
    public inline function hasFrame(frame: Int): Bool {
        return buffer.exists(frame);
    }

    /**
     * Retrieves the input for the specified frame.
     */
    public function getFrameInput(frame: Int): Int {
        var input = buffer.get(frame);
        return input != null ? input : 0;
    }

    /**
     * Pops and purges inputs up to the specified frame horizon.
     */
    public function popUpTo(frameHorizon: Int): Void {
        var keysToRemove = new Array<Int>();
        for (f in buffer.keys()) {
            if (f < frameHorizon) {
                keysToRemove.push(f);
            }
        }
        for (k in keysToRemove) {
            buffer.remove(k);
        }
    }

    private inline function storeInput(frame: Int, input: Int): Void {
        buffer.set(frame, input);
        if (frame > highestReceivedFrame) {
            highestReceivedFrame = frame;
        }
    }

    public function clear(): Void {
        buffer = new IntMap<Int>();
        highestReceivedFrame = -1;
        lowestBufferedFrame = 0;
    }
}
