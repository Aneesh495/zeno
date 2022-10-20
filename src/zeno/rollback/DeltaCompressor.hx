package zeno.rollback;

import haxe.io.Bytes;
import zeno.core.Buffer;

/**
 * Differential state compressor.
 * Computes byte-level XOR deltas with Run-Length Encoding (RLE) across successive frames,
 * dramatically shrinking network synchronization bandwidth and snapshot memory usage.
 */
class DeltaCompressor {
    /**
     * Compresses target buffer relative to baseline buffer using XOR + RLE.
     */
    public static function compress(baseline: Bytes, target: Bytes): Buffer {
        var baseLen = baseline != null ? baseline.length : 0;
        var targetLen = target != null ? target.length : 0;

        var out = new Buffer(targetLen + 16);
        out.writeInt32(targetLen);

        var i = 0;
        while (i < targetLen) {
            var bTarget = target.get(i);
            var bBase = (i < baseLen) ? baseline.get(i) : 0;
            var xorVal = bTarget ^ bBase;

            if (xorVal == 0) {
                // Count run of zeros
                var zeroRun = 1;
                while (i + zeroRun < targetLen && zeroRun < 255) {
                    var nextTarget = target.get(i + zeroRun);
                    var nextBase = (i + zeroRun < baseLen) ? baseline.get(i + zeroRun) : 0;
                    if ((nextTarget ^ nextBase) != 0) break;
                    zeroRun++;
                }

                // Opcode 0x00 indicates zero run followed by length byte
                out.writeByte(0x00);
                out.writeByte(zeroRun);
                i += zeroRun;
            } else {
                // Opcode 0x01 indicates literal non-zero delta byte
                out.writeByte(0x01);
                out.writeByte(xorVal);
                i++;
            }
        }

        return out;
    }

    /**
     * Decompresses delta buffer against baseline to reconstruct target buffer.
     */
    public static function decompress(baseline: Bytes, delta: Buffer): Bytes {
        delta.setReadPosition(0);
        var targetLen = delta.readInt32();
        var target = Bytes.alloc(targetLen);
        var baseLen = baseline != null ? baseline.length : 0;

        var outIdx = 0;
        while (outIdx < targetLen && delta.getBytesAvailable() > 0) {
            var opcode = delta.readByte();
            if (opcode == 0x00) {
                // Zero run: bytes match baseline
                var runLen = delta.readByte();
                for (r in 0...runLen) {
                    if (outIdx >= targetLen) break;
                    var bBase = (outIdx < baseLen) ? baseline.get(outIdx) : 0;
                    target.set(outIdx, bBase);
                    outIdx++;
                }
            } else if (opcode == 0x01) {
                // Literal delta byte
                var xorVal = delta.readByte();
                var bBase = (outIdx < baseLen) ? baseline.get(outIdx) : 0;
                target.set(outIdx, bBase ^ xorVal);
                outIdx++;
            }
        }

        return target;
    }
}
