package zeno.spatial;

import haxe.Int32;

/**
 * Morton codes (Z-order curve) bit interleaving functions.
 * Maps multidimensional spatial coordinates into 1D linear integer sequences
 * preserving spatial locality for cache-coherent sorting.
 */
class Morton {
    /**
     * Interleaves the 16 lower bits of x and y into a 32-bit Morton code.
     */
    public static function encode2D(x: Int, y: Int): Int32 {
        var ux = (x & 0xFFFF);
        var uy = (y & 0xFFFF);
        return part1By1(ux) | (part1By1(uy) << 1);
    }

    /**
     * Spreads bits of a 16-bit integer so that each bit is separated by 1 zero bit.
     */
    private static inline function part1By1(x: Int): Int32 {
        var v: Int32 = x & 0x0000FFFF;
        v = (v | (v << 8)) & 0x00FF00FF;
        v = (v | (v << 4)) & 0x0F0F0F0F;
        v = (v | (v << 2)) & 0x33333333;
        v = (v | (v << 1)) & 0x55555555;
        return v;
    }
}
