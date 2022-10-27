package zeno.net;

import haxe.io.Bytes;
import zeno.core.Buffer;
import zeno.core.CRC32C;

/**
 * Redundant bit-packed client input datagram.
 * Transmits current frame input alongside trailing historical inputs (F-1, F-2, F-3)
 * to achieve instant recovery from UDP packet loss without round-trip retransmissions.
 */
class InputPacket {
    public var sequence: Int;
    public var targetFrame: Int;
    public var currentInput: Int;
    public var pastInputs: Array<Int>; // Last 3 trailing inputs

    public function new(seq: Int, frame: Int, currentInput: Int, ?trailing: Array<Int>) {
        this.sequence = seq;
        this.targetFrame = frame;
        this.currentInput = currentInput;
        this.pastInputs = trailing != null ? trailing : [0, 0, 0];
    }

    /**
     * Serializes input packet into a binary buffer with CRC32-C checksum.
     */
    public function serialize(): Buffer {
        var buf = new Buffer(32);
        buf.writeInt32(sequence);
        buf.writeInt32(targetFrame);
        buf.writeInt32(currentInput);
        buf.writeByte(pastInputs.length);
        for (i in 0...pastInputs.length) {
            buf.writeInt32(pastInputs[i]);
        }

        var raw = buf.toBytes();
        var checksum = CRC32C.compute(raw);
        buf.writeInt32(checksum);
        return buf;
    }

    /**
     * Deserializes and validates input packet. Returns null if checksum fails.
     */
    public static function deserialize(buf: Buffer): InputPacket {
        buf.setReadPosition(0);
        var seq = buf.readInt32();
        var frame = buf.readInt32();
        var curr = buf.readInt32();
        var numPast = buf.readByte();

        var trailing = new Array<Int>();
        for (i in 0...numPast) {
            trailing.push(buf.readInt32());
        }

        // Validate checksum
        var payloadLen = buf.getReadPosition();
        var readChecksum = buf.readInt32();

        var rawBytes = buf.getRawBytes();
        var calculatedChecksum = CRC32C.compute(rawBytes, 0, payloadLen);

        if (readChecksum != calculatedChecksum) {
            // Corrupt packet rejected
            return null;
        }

        return new InputPacket(seq, frame, curr, trailing);
    }
}
