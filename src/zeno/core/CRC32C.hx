package zeno.core;

import haxe.io.Bytes;
import haxe.Int32;
import haxe.ds.Vector;

/**
 * CRC32-C (Castagnoli) checksum generator using precomputed lookup table.
 * Standardized in RFC 3720 (iSCSI) and SCTP, providing stronger error
 * detection polynomials than IEEE 802.3 CRC32.
 */
class CRC32C {
    private static var TABLE: Vector<Int32> = buildTable();

    private static function buildTable(): Vector<Int32> {
        var table = new Vector<Int32>(256);
        var poly: Int32 = 0x82F63B78; // Castagnoli reversed representation
        for (i in 0...256) {
            var crc: Int32 = i;
            for (j in 0...8) {
                if ((crc & 1) != 0) {
                    crc = (crc >>> 1) ^ poly;
                } else {
                    crc = crc >>> 1;
                }
            }
            table[i] = crc;
        }
        return table;
    }

    /**
     * Calculates the CRC32-C checksum over the given byte buffer.
     * @param bytes Byte data to checksum.
     * @param offset Starting byte index.
     * @param length Number of bytes to process (-1 for remainder).
     * @return 32-bit checksum.
     */
    public static function compute(bytes: Bytes, offset: Int = 0, length: Int = -1): Int32 {
        if (bytes == null) return 0;
        var len = length < 0 ? bytes.length - offset : length;
        if (len <= 0) return 0;

        var crc: Int32 = 0xFFFFFFFF;
        var end = offset + len;
        for (i in offset...end) {
            var b = bytes.get(i);
            var tableIndex = (crc ^ b) & 0xFF;
            crc = (crc >>> 8) ^ TABLE[tableIndex];
        }
        return crc ^ 0xFFFFFFFF;
    }

    /**
     * Progressively updates an in-flight CRC32-C calculation with new bytes.
     */
    public static function update(runningCrc: Int32, byteVal: Int): Int32 {
        var tableIndex = (runningCrc ^ byteVal) & 0xFF;
        return (runningCrc >>> 8) ^ TABLE[tableIndex];
    }
}
