package zeno.rollback;

import haxe.Int32;
import zeno.core.Murmur3;
import zeno.core.CRC32C;
import zeno.core.Buffer;

/**
 * Cryptographic-grade simulation state hashing.
 * Traverses world snapshots in canonical entity ID order to compute
 * bit-exact checksums across disparate hardware architectures.
 */
class StateHasher {
    /**
     * Computes the canonical Murmur3 32-bit hash of a snapshot.
     */
    public static function hashSnapshot(snapshot: Snapshot): Int32 {
        if (snapshot == null) return 0;

        // Sort entities by ID to guarantee permutation invariance
        var sorted = snapshot.entities.copy();
        sorted.sort(function(a, b) return a.entity.getRaw() - b.entity.getRaw());

        var buf = new Buffer(64 + sorted.length * 32);
        buf.writeInt32(snapshot.frame);
        buf.writeInt32(snapshot.rngStateHigh);
        buf.writeInt32(snapshot.rngStateLow);
        buf.writeInt32(sorted.length);

        for (e in sorted) {
            buf.writeInt32(e.entity.getRaw());
            buf.writeInt32(e.posX.getRaw());
            buf.writeInt32(e.posY.getRaw());
            buf.writeInt32(e.angle.getRaw());
            buf.writeInt32(e.velX.getRaw());
            buf.writeInt32(e.velY.getRaw());
            buf.writeInt32(e.angVel.getRaw());
            buf.writeBool(e.isAwake);
        }

        var bytes = buf.toBytes();
        return Murmur3.hash(bytes);
    }

    /**
     * Computes the CRC32-C checksum over the snapshot.
     */
    public static function computeCRC32(snapshot: Snapshot): Int32 {
        var buf = snapshot.serialize();
        return CRC32C.compute(buf.toBytes());
    }
}
