package zeno.math;

import haxe.Int32;
import haxe.Int64;

/**
 * Deterministic Pseudo-Random Number Generator (PCG-XSH-RR 32/16 scheme).
 * Produces identical pseudo-random distributions across all compile targets,
 * operating purely on 64-bit integer linear congruential state updates.
 * State can be saved and restored for rollback frame synchronization.
 */
class FPRandom {
    private var state: Int64;
    private var inc: Int64;

    private static var DEFAULT_MULTIPLIER(default, never): Int64 = Int64.make(0x5851f42d, 0x4c957f2d);

    public function new(initSeed: Int32 = 42, initSeq: Int32 = 54) {
        setSeed(initSeed, initSeq);
    }

    public function setSeed(initSeed: Int32, initSeq: Int32 = 54): Void {
        this.state = Int64.ofInt(0);
        // inc = (initSeq << 1) | 1
        var seq64 = Int64.ofInt(initSeq);
        this.inc = Int64.or(Int64.shl(seq64, 1), Int64.ofInt(1));
        nextInt32();
        this.state = Int64.add(this.state, Int64.ofInt(initSeed));
        nextInt32();
    }

    /**
     * Generates a 32-bit unsigned pseudo-random integer.
     */
    public function nextInt32(): Int32 {
        var oldState = this.state;
        // state = state * MULTIPLIER + inc
        this.state = Int64.add(Int64.mul(oldState, DEFAULT_MULTIPLIER), this.inc);

        // xorshift = ((oldState >> 18) ^ oldState) >> 27
        var xorshift = Int64.shr(
            Int64.xor(Int64.shr(oldState, 18), oldState),
            27
        );
        var xor32 = Int64.toInt(xorshift);
        // rot = oldState >> 59
        var rot = Int64.toInt(Int64.shr(oldState, 59)) & 31;
        // (xor32 >>> rot) | (xor32 << ((-rot) & 31))
        return (xor32 >>> rot) | (xor32 << ((-rot) & 31));
    }

    /**
     * Generates an integer in range [min, max] inclusive.
     */
    public function nextRange(min: Int, max: Int): Int {
        if (min >= max) return min;
        var span = (max - min) + 1;
        var r = nextInt32() & 0x7FFFFFFF;
        return min + (r % span);
    }

    /**
     * Generates a deterministic fixed-point number in range [0, 1].
     */
    public function nextFixed(): FPNumber {
        var r = (nextInt32() & 0xFFFF);
        return FPNumber.fromRaw(r);
    }

    /**
     * Generates a deterministic fixed-point number in range [min, max].
     */
    public function nextFixedRange(min: FPNumber, max: FPNumber): FPNumber {
        var t = nextFixed();
        return FPMath.lerp(min, max, t);
    }

    /**
     * Generates a fixed-point angle in radians in range [-PI, PI].
     */
    public function nextAngle(): FPNumber {
        return nextFixedRange(-FPNumber.PI, FPNumber.PI);
    }

    /**
     * Generates a random 2D point inside or on a unit circle of given radius.
     */
    public function nextVector2(radius: FPNumber): FPVector2 {
        var angle = nextAngle();
        var r = FPMath.sqrt(nextFixed()) * radius;
        var sc = FPMath.sinCos(angle);
        return new FPVector2(sc.cos * r, sc.sin * r);
    }

    public function getStateLow(): Int32 return state.low;
    public function getStateHigh(): Int32 return state.high;

    public function restoreState(high: Int32, low: Int32): Void {
        this.state = Int64.make(high, low);
    }
}
