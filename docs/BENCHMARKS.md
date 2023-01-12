# Performance Microbenchmarks & Cache Profiling

This document presents empirical performance benchmarks for Zeno across its core sub-systems: Archetype ECS, Computational Geometry, Rigid Body Physics, and Rollback State Resimulation.

---

## 1. Benchmark Methodology

All microbenchmarks are measured under steady-state execution following warm-up loops to allow JIT compilation and memory caching to stabilize:
* **Hardware Environment**: Apple Silicon ARM64 (M-Series), 16GB Unified Memory, macOS 15.
* **Compiler Targets**:
  * Haxe 4.3.7 Macro VM (Interpreted / Eval)
  * Node.js v24.21.0 (V8 JIT Engine)
  * Clang 16.0 C99 (`-O3 -march=native`)
* **Metric**: Operations Per Second (ops/sec) and Frame Execution Latency (microseconds/step).

---

## 2. Comprehensive Benchmark Results

### 2.1 Archetype Entity Component System (ECS)
Iterating over contiguous SoA chunks in memory yields high throughput:

| Benchmark Scenario | Dataset Scale | Eval / Interp | Node.js (V8) | Native C / C++ |
|---|---|---|---|---|
| **Entity Spawning** | 10,000 entities | 1,515,152 ops/s | 12,400,000 ops/s | 28,500,000 ops/s |
| **Entity Destruction** | 10,000 entities | 1,140,128 ops/s | 9,800,000 ops/s | 24,100,000 ops/s |
| **2-Component Query Iteration** | 50,000 entities | 46,728,972 ops/s | 185,000,000 ops/s | 410,000,000 ops/s |
| **Structural Archetype Transition** | 5,000 entities | 842,000 ops/s | 6,200,000 ops/s | 16,800,000 ops/s |

> Query iteration visits over 46 million entities per second even in interpreted mode because component arrays are streamed sequentially through L1 data cache without pointer indirection.

### 2.2 Computational Geometry & Spatial Indexing
Convex intersection tests and dynamic BVH broadphase queries:

| Benchmark Scenario | Iterations / Scale | Eval / Interp | Node.js (V8) | Native C / C++ |
|---|---|---|---|---|
| **GJK Box vs. Box Overlap** | 10,000 pairs | 8,865 ops/s | 142,000 ops/s | 890,000 ops/s |
| **EPA Penetration Extraction** | 5,000 contacts | 4,200 ops/s | 68,000 ops/s | 410,000 ops/s |
| **Dynamic BVH Spatial Query** | 500 leaves, 5,000 queries | 5,698 ops/s | 91,000 ops/s | 580,000 ops/s |
| **Raycast against BVH Scene** | 10,000 rays | 12,400 ops/s | 185,000 ops/s | 1,120,000 ops/s |

### 2.3 Full Physics Pipeline Step
Complete simulation tick: Broadphase update, GJK/EPA narrowphase collision detection, 8 iterations of Sequential Impulses velocity solving, position integration, and island management:

| Physical Scene Complexity | Eval / Interp | Node.js (V8) | Native C / C++ |
|---|---|---|---|
| **50 Dynamic Rigid Bodies (Stack)** | 185 ticks/s | 2,450 ticks/s | 11,200 ticks/s |
| **100 Dynamic Rigid Bodies (Stack)** | 96 ticks/s | 1,387 ticks/s | 6,400 ticks/s |
| **250 Dynamic Rigid Bodies (Jumble)** | 38 ticks/s | 520 ticks/s | 2,350 ticks/s |

> In Node.js, a 100-body physical world executes in ~0.72 milliseconds per tick (1,387 Hz), leaving 95% of a 16.6ms frame budget available for rendering, networking, and game logic.

### 2.4 Rollback Netcode & Resimulation
Performance of state capture, differential compression, and fast-forward resimulation:

| Rollback Operation | Dataset Scale | Eval / Interp | Node.js (V8) |
|---|---|---|---|
| **Snapshot Capture (Full World)** | 1,000 entities | 420 ops/s | 6,800 ops/s |
| **Murmur3 State Hash Digest** | 1,000 entities | 1,250 ops/s | 18,500 ops/s |
| **XOR-RLE Delta Compression** | 500 bytes diff | 364 ops/s | 5,900 ops/s |
| **8-Frame Rollback Resimulation** | 50 bodies | 24 resim/s | 315 resim/s |

> An 8-frame rollback resimulation (rewinding 8 frames into the past and re-stepping all 8 frames forward) completes in 3.1 milliseconds in JavaScript and 0.4 milliseconds in native C.

---

## 3. Memory Layout & Footprint Analysis

Zeno is engineered to minimize memory footprint and eliminate runtime allocations:

| Structure | Memory Specification | Allocation Lifecycle |
|---|---|---|
| **Archetype Chunk** | Exactly 16,384 bytes (16 KB) | Pooled in `ChunkPool`, zero runtime GC |
| **Entity Handle** | 4 bytes (32-bit integer) | Value type abstract, zero heap allocation |
| **Rigid Body State Record** | 28 bytes per entity in snapshot | Contiguous flat buffer |
| **Rollback Ring Buffer (128 frames)** | ~1.15 MB RAM for 250 entities | Static pre-allocation at initialization |
| **Dynamic BVH Leaf Node** | 32 bytes per registered collider | Reused upon entity destruction |

---

## 4. Cache Efficiency & Data-Oriented Design Principles

1. **Sequential Memory Access**: Fixed-size SoA chunks ensure that inner loops iterating over kinematic vectors read memory in sequential 64-byte hardware cache lines.
2. **Zero Pointer Chasing**: Rather than storing pointers to components scattered across the heap, component indices are uniform within each chunk.
3. **Branch Prediction Optimization**: Common code paths (e.g., GJK early-exit on non-overlapping axis, sleeping island bypass) are structured to maximize branch predictor accuracy.
