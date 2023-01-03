# Determinism & Fixed-Point Mathematics in Zeno

Cross-platform determinism is the foundational invariant of Zeno. In networked physics simulations, lockstep architectures, and rollback netcode, even a single-bit divergence in floating-point computation will compound exponentially over simulation ticks, resulting in complete desynchronization ("desync") between peers.

This document details the engineering decisions, mathematical proofs, and implementation techniques employed in Zeno to guarantee bit-exact simulation reproducibility across disparate architectures (x86_64, ARM64, WebAssembly, and JavaScript runtimes).

---

## 1. The Fallacy of IEEE 754 Floating-Point Determinism

Standard 32-bit (`float`) and 64-bit (`double`) floating-point arithmetic compliant with IEEE 754 is non-deterministic across differing CPU microarchitectures, operating systems, and compiler optimization flags for several well-documented reasons:

1. **Fused Multiply-Add (FMA)**: Contemporary x86 (AVX2/FMA3) and ARM (NEON) processors support hardware FMA instructions computing `(a * b) + c` with a single rounding step at the end. Older processors compute multiplication followed by addition, introducing intermediate rounding. This produces differing results for identical equations.
2. **Intermediate Register Precision**: The legacy x87 floating-point unit uses 80-bit internal registers, whereas SSE2 and ARM use 32-bit or 64-bit vector registers. Compiler spills to the stack truncate 80-bit values to 32/64 bits unpredictably depending on register pressure and optimization level (`-O2` vs `-O3`).
3. **Transcendental Library Variations**: Mathematical functions such as `sin()`, `cos()`, `sqrt()`, and `atan2()` in the C standard library (`libm`) are not standardized by IEEE 754. GLIBC on Linux, MSVCRT on Windows, Apple Libm on macOS, and JavaScript V8 provide differing bit-level implementations.
4. **Subnormal Numbers and Flush-to-Zero (FTZ)**: Different processor architectures handle denormalized floating-point numbers differently depending on whether FTZ (Flush-To-Zero) or DAZ (Denormals-Are-Zero) hardware flags are asserted.

To eliminate every source of platform variation, Zeno completely disallows hardware floating-point operations in simulation state updates, relying entirely on bit-exact integer fixed-point arithmetic.

---

## 2. Q16.16 Fixed-Point Representation (`FPNumber`)

Zeno implements a signed 32-bit Q16.16 fixed-point number format:

```
 31 30                               16 15                                0
┌──┬───────────────────────────────────┬───────────────────────────────────┐
│S │       Integer Part (15 bits)      │     Fractional Part (16 bits)     │
└──┴───────────────────────────────────┴───────────────────────────────────┘
```

* **Sign Bit (`S`)**: 1 bit (Two's complement).
* **Integer Range**: `-32,768` to `+32,767`.
* **Fractional Precision**: `1 / 65536` (~`0.0000152587890625`).
* **Scale Factor**: `1 << 16` (`65536`).

### 2.1 Arithmetic Operations and Saturation Bounds

All basic arithmetic operations are implemented with deterministic two's complement integer logic:

* **Addition / Subtraction**: Direct 32-bit integer addition and subtraction:
  ```haxe
  public static inline function add(a: FPNumber, b: FPNumber): FPNumber {
      return new FPNumber(a.rawValue + b.rawValue);
  }
  ```

* **Multiplication with Saturation**: To prevent catastrophic wrap-around when multiplying large coordinate values, 64-bit intermediate products are checked against saturation limits:
  ```haxe
  public static inline function mul(a: FPNumber, b: FPNumber): FPNumber {
      var prod64: Int64 = Int64.mul(Int64.ofInt(a.rawValue), Int64.ofInt(b.rawValue));
      var shifted: Int64 = Int64.shr(prod64, 16);
      if (Int64.compare(shifted, MAX_64) > 0) return MAX_VALUE;
      if (Int64.compare(shifted, MIN_64) < 0) return MIN_VALUE;
      return new FPNumber(Int64.toInt(shifted));
  }
  ```

* **Division**: Checked division by zero yielding saturating maximums:
  ```haxe
  public static inline function div(a: FPNumber, b: FPNumber): FPNumber {
      if (b.rawValue == 0) {
          return (a.rawValue >= 0) ? MAX_VALUE : MIN_VALUE;
      }
      var num64: Int64 = Int64.shl(Int64.ofInt(a.rawValue), 16);
      var quot64: Int64 = Int64.div(num64, Int64.ofInt(b.rawValue));
      if (Int64.compare(quot64, MAX_64) > 0) return MAX_VALUE;
      if (Int64.compare(quot64, MIN_64) < 0) return MIN_VALUE;
      return new FPNumber(Int64.toInt(quot64));
  }
  ```

---

## 3. Transcendental Mathematical Functions via CORDIC (`FPMath`)

Standard math libraries cannot be invoked in deterministic simulations. Zeno computes square roots, trigonometry, and angles using pure integer algorithms:

### 3.1 Integer Digit-by-Digit Square Root
The square root function implements an exact digit-by-digit radical extraction:
```haxe
public static function sqrt(x: FPNumber): FPNumber {
    if (x.rawValue <= 0) return FPNumber.ZERO;
    var val64: Int64 = Int64.shl(Int64.ofInt(x.rawValue), 16);
    var rem64: Int64 = Int64.make(0, 0);
    var root64: Int64 = Int64.make(0, 0);

    for (i in 0...24) {
        root64 = Int64.shl(root64, 1);
        rem64 = Int64.or(Int64.shl(rem64, 2), Int64.and(Int64.shr(val64, 46 - (i * 2)), Int64.ofInt(3)));
        var test64: Int64 = Int64.add(Int64.shl(root64, 1), Int64.ofInt(1));
        if (Int64.compare(rem64, test64) >= 0) {
            rem64 = Int64.sub(rem64, test64);
            root64 = Int64.add(root64, Int64.ofInt(1));
        }
    }
    return new FPNumber(Int64.toInt(root64));
}
```

### 3.2 CORDIC Trigonometry
CORDIC (Coordinate Rotation Digital Computer) evaluates trigonometric functions (`sin`, `cos`, `atan2`) using only addition, bit-shifts, and a compact precomputed table of arctangent angles (`atan(2^-i)`):

```
Iteration Step:
  x_{i+1} = x_i - d_i * (y_i >> i)
  y_{i+1} = y_i + d_i * (x_i >> i)
  z_{i+1} = z_i - d_i * atan(2^-i)
  where d_i = sign(z_i)
```

By executing 16 discrete CORDIC iterations, Zeno achieves 16-bit fractional precision with zero floating-point registers and identical results across all architectures.

---

## 4. Deterministic Randomness (`FPRandom`)

Gameplay randomness and physics perturbation must be identical on all connected simulation nodes. Zeno uses the high-performance **Xoroshiro128+** PRNG:
* 128-bit state space represented as two 64-bit words (`state0`, `state1`).
* State transition functions use only bitwise `xor`, `shift`, and `rotl` (rotate left).
* Both state halves are captured during snapshot creation and restored bit-for-bit upon rollback resimulation.

---

## 5. State Hasher & Checksum Verification (`StateHasher`)

To guarantee that all clients remain in exact synchronization, Zeno computes a canonical 32-bit Murmur3 state hash on every snapshot:

1. **Deterministic Entity Ordering**: Entities are iterated in strict generational index order.
2. **State Serializer**: The raw integer fields of each entity (position X/Y, angle, linear velocity X/Y, angular velocity, asleep status) are packed into a contiguous byte stream.
3. **PRNG State Inclusion**: Both 64-bit halves of the active random seed are appended.
4. **Murmur3 Avalanche Hash**: The buffer is digested using Murmur3 with seed `0x9747B28C`.

If two clients record identical inputs, their state hashes are guaranteed to match bit-for-bit. Any divergence flags an immediate desynchronization event with exact frame attribution.
