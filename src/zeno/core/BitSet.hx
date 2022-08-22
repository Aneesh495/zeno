package zeno.core;

import haxe.Int32;
import haxe.ds.Vector;

/**
 * High-performance bit set supporting arbitrary bit lengths.
 * Utilizes 32-bit integer words with fast bitwise operations,
 * population counting, and trailing zero scanning.
 * Essential for ECS archetype masks and collision layer filters.
 */
class BitSet {
    private var words: Vector<Int32>;
    private var capacity: Int;

    /**
     * Initializes a bit set with a designated bit capacity.
     * @param initialCapacity Number of bits to support initially.
     */
    public function new(initialCapacity: Int = 64) {
        this.capacity = initialCapacity > 0 ? initialCapacity : 64;
        var wordCount = (this.capacity + 31) >> 5;
        this.words = new Vector<Int32>(wordCount);
        for (i in 0...wordCount) {
            this.words[i] = 0;
        }
    }

    /**
     * Sets the bit at the specified index to true (1).
     * Automatically expands capacity if needed.
     */
    public function set(index: Int): Void {
        ensureCapacity(index + 1);
        var wordIndex = index >> 5;
        var bitOffset = index & 31;
        var current = words[wordIndex];
        words[wordIndex] = current | (1 << bitOffset);
    }

    /**
     * Clears the bit at the specified index to false (0).
     */
    public function clear(index: Int): Void {
        if (index >= capacity) return;
        var wordIndex = index >> 5;
        var bitOffset = index & 31;
        var current = words[wordIndex];
        words[wordIndex] = current & ~(1 << bitOffset);
    }

    /**
     * Tests whether the bit at the specified index is set.
     */
    public function get(index: Int): Bool {
        if (index >= capacity) return false;
        var wordIndex = index >> 5;
        var bitOffset = index & 31;
        return (words[wordIndex] & (1 << bitOffset)) != 0;
    }

    /**
     * Resets all bits in the bit set to 0.
     */
    public function reset(): Void {
        var len = words.length;
        for (i in 0...len) {
            words[i] = 0;
        }
    }

    /**
     * Returns true if all set bits in the `other` bitset are also set in `this`.
     * Used for component query matching (archetype superset test).
     */
    public function containsAll(other: BitSet): Bool {
        var minWords = other.words.length < this.words.length ? other.words.length : this.words.length;
        for (i in 0...minWords) {
            var otherWord = other.words[i];
            if ((this.words[i] & otherWord) != otherWord) {
                return false;
            }
        }
        // If other has more words, they must all be 0 in other
        if (other.words.length > this.words.length) {
            for (i in minWords...other.words.length) {
                if (other.words[i] != 0) return false;
            }
        }
        return true;
    }

    /**
     * Returns true if any bit is shared between `this` and `other`.
     */
    public function intersects(other: BitSet): Bool {
        var minWords = other.words.length < this.words.length ? other.words.length : this.words.length;
        for (i in 0...minWords) {
            if ((this.words[i] & other.words[i]) != 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * Counts the total number of set bits (Hamming weight).
     */
    public function countSetBits(): Int {
        var count = 0;
        var len = words.length;
        for (i in 0...len) {
            count += popcount32(words[i]);
        }
        return count;
    }

    /**
     * Creates an exact independent copy of this bit set.
     */
    public function clone(): BitSet {
        var copy = new BitSet(this.capacity);
        var len = this.words.length;
        for (i in 0...len) {
            copy.words[i] = this.words[i];
        }
        return copy;
    }

    /**
     * Computes a deterministic 32-bit hash of the bitset content.
     */
    public function hashCode(): Int32 {
        var h: Int32 = 0x811c9dc5; // FNV-1a basis
        var len = words.length;
        for (i in 0...len) {
            var w = words[i];
            h = (h ^ (w & 0xFF)) * 0x01000193;
            h = (h ^ ((w >> 8) & 0xFF)) * 0x01000193;
            h = (h ^ ((w >> 16) & 0xFF)) * 0x01000193;
            h = (h ^ ((w >> 24) & 0xFF)) * 0x01000193;
        }
        return h;
    }

    /**
     * Checks equality with another BitSet.
     */
    public function equals(other: BitSet): Bool {
        if (other == null) return false;
        var maxLen = this.words.length > other.words.length ? this.words.length : other.words.length;
        for (i in 0...maxLen) {
            var w1 = i < this.words.length ? this.words[i] : 0;
            var w2 = i < other.words.length ? other.words[i] : 0;
            if (w1 != w2) return false;
        }
        return true;
    }

    private function ensureCapacity(requiredBits: Int): Void {
        if (requiredBits <= capacity) return;
        var newCap = capacity;
        while (newCap < requiredBits) {
            newCap = newCap << 1;
        }
        var newWordCount = (newCap + 31) >> 5;
        var newWords = new Vector<Int32>(newWordCount);
        var oldLen = words.length;
        for (i in 0...oldLen) {
            newWords[i] = words[i];
        }
        for (i in oldLen...newWordCount) {
            newWords[i] = 0;
        }
        this.capacity = newCap;
        this.words = newWords;
    }

    private static inline function popcount32(x: Int32): Int {
        var n = x - ((x >> 1) & 0x55555555);
        n = (n & 0x33333333) + ((n >> 2) & 0x33333333);
        n = (n + (n >> 4)) & 0x0F0F0F0F;
        n = n + (n >> 8);
        n = n + (n >> 16);
        return n & 0x3F;
    }
}
