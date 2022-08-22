package zeno.core;

import haxe.io.Bytes;

/**
 * Contiguous fixed-size memory chunk allocator.
 * Manages pools of uniform byte buffers (typically 16KB or 64KB)
 * to store contiguous Struct-of-Arrays (SoA) component tables
 * with zero memory fragmentation and fast cache locality.
 */
class ChunkPool {
    private var chunkSize: Int;
    private var freeChunks: Array<Bytes>;
    private var totalCreated: Int;

    /**
     * @param chunkSizeInBytes Size of each chunk in bytes (default 16384 = 16KB).
     * @param prewarmCount Number of chunks to preallocate immediately.
     */
    public function new(chunkSizeInBytes: Int = 16384, prewarmCount: Int = 8) {
        this.chunkSize = chunkSizeInBytes;
        this.freeChunks = new Array<Bytes>();
        this.totalCreated = 0;

        for (i in 0...prewarmCount) {
            freeChunks.push(Bytes.alloc(chunkSize));
            totalCreated++;
        }
    }

    public inline function getChunkSize(): Int return chunkSize;
    public inline function getFreeChunkCount(): Int return freeChunks.length;
    public inline function getTotalCreated(): Int return totalCreated;

    /**
     * Obtains a free chunk buffer.
     */
    public function allocateChunk(): Bytes {
        if (freeChunks.length > 0) {
            return freeChunks.pop();
        }
        totalCreated++;
        return Bytes.alloc(chunkSize);
    }

    /**
     * Recycles a chunk buffer back into the pool.
     */
    public function recycleChunk(chunk: Bytes): Void {
        if (chunk == null || chunk.length != chunkSize) return;
        // Zero-fill chunk header/content for safety
        chunk.fill(0, chunk.length, 0);
        freeChunks.push(chunk);
    }

    public function purge(): Void {
        while (freeChunks.length > 0) {
            freeChunks.pop();
        }
    }
}
