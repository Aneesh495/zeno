package zeno.core;

import haxe.io.Bytes;
import haxe.Int32;

/**
 * Deterministic MurmurHash3 (32-bit variant) implementation.
 * Used for fast, bit-exact cryptographic-style state hashing
 * across all targets to immediately detect simulation divergence.
 */
class Murmur3 {
    private static inline var C1: Int32 = 0xcc9e2d51;
    private static inline var C2: Int32 = 0x1b873593;
    private static inline var R1: Int = 15;
    private static inline var R2: Int = 13;
    private static inline var M: Int32 = 5;
    private static inline var N: Int32 = 0xe6546b64;

    /**
     * Computes the 32-bit Murmur3 hash of the provided bytes buffer.
     * @param data The byte array to hash.
     * @param seed Optional seed value (defaults to 0).
     * @return 32-bit integer hash code.
     */
    public static function hash(data: Bytes, seed: Int32 = 0): Int32 {
        if (data == null || data.length == 0) return seed;

        var len = data.length;
        var h1: Int32 = seed;
        var roundedEnd = len & ~3;

        var i = 0;
        while (i < roundedEnd) {
            var b0: Int32 = data.get(i);
            var b1: Int32 = data.get(i + 1);
            var b2: Int32 = data.get(i + 2);
            var b3: Int32 = data.get(i + 3);
            var k1: Int32 = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);

            k1 = k1 * C1;
            k1 = rotl32(k1, R1);
            k1 = k1 * C2;

            h1 = h1 ^ k1;
            h1 = rotl32(h1, R2);
            h1 = h1 * M + N;

            i += 4;
        }

        var k1Tail: Int32 = 0;
        var rem = len & 3;
        if (rem >= 3) {
            var b2: Int32 = data.get(roundedEnd + 2);
            k1Tail = k1Tail ^ (b2 << 16);
        }
        if (rem >= 2) {
            var b1: Int32 = data.get(roundedEnd + 1);
            k1Tail = k1Tail ^ (b1 << 8);
        }
        if (rem >= 1) {
            var b0: Int32 = data.get(roundedEnd);
            k1Tail = k1Tail ^ b0;
            k1Tail = k1Tail * C1;
            k1Tail = rotl32(k1Tail, R1);
            k1Tail = k1Tail * C2;
            h1 = h1 ^ k1Tail;
        }

        // Finalization avalanche
        h1 = h1 ^ len;
        h1 = fmix32(h1);
        return h1;
    }

    /**
     * Hashes a sequence of 32-bit integers directly without byte allocations.
     */
    public static function hashInts(ints: Array<Int32>, seed: Int32 = 0): Int32 {
        var h1: Int32 = seed;
        var len = ints.length;
        for (i in 0...len) {
            var k1 = ints[i] * C1;
            k1 = rotl32(k1, R1);
            k1 = k1 * C2;

            h1 = h1 ^ k1;
            h1 = rotl32(h1, R2);
            h1 = h1 * M + N;
        }

        h1 = h1 ^ (len * 4);
        h1 = fmix32(h1);
        return h1;
    }

    private static inline function rotl32(x: Int32, r: Int): Int32 {
        return (x << r) | (x >>> (32 - r));
    }

    private static inline function fmix32(h: Int32): Int32 {
        h = h ^ (h >>> 16);
        h = h * 0x85ebca6b;
        h = h ^ (h >>> 13);
        h = h * 0xc2b2ae35;
        h = h ^ (h >>> 16);
        return h;
    }
}
