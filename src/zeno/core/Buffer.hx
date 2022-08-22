package zeno.core;

import haxe.io.Bytes;
import haxe.Int32;
import haxe.Int64;

/**
 * High-performance binary buffer reader and writer.
 * Provides deterministic little-endian serialization of primitives,
 * fixed-point numbers, strings, and raw byte arrays.
 */
class Buffer {
    private var data: Bytes;
    private var readPos: Int;
    private var writePos: Int;
    private var capacity: Int;

    public function new(initialCapacity: Int = 256) {
        this.capacity = initialCapacity > 0 ? initialCapacity : 256;
        this.data = Bytes.alloc(this.capacity);
        this.readPos = 0;
        this.writePos = 0;
    }

    public static function wrap(bytes: Bytes): Buffer {
        var buf = new Buffer(bytes.length);
        buf.data = bytes;
        buf.capacity = bytes.length;
        buf.writePos = bytes.length;
        buf.readPos = 0;
        return buf;
    }

    public inline function getWritePosition(): Int return writePos;
    public inline function getReadPosition(): Int return readPos;
    public inline function getCapacity(): Int return capacity;
    public inline function getBytesAvailable(): Int return writePos - readPos;

    public inline function setReadPosition(pos: Int): Void {
        if (pos >= 0 && pos <= writePos) {
            this.readPos = pos;
        }
    }

    public inline function setWritePosition(pos: Int): Void {
        if (pos >= 0 && pos <= capacity) {
            this.writePos = pos;
        }
    }

    public inline function reset(): Void {
        this.readPos = 0;
        this.writePos = 0;
    }

    public function ensureCapacity(additionalBytes: Int): Void {
        var required = writePos + additionalBytes;
        if (required <= capacity) return;

        var newCap = capacity;
        while (newCap < required) {
            newCap = newCap << 1;
        }
        var newBytes = Bytes.alloc(newCap);
        newBytes.blit(0, data, 0, writePos);
        this.data = newBytes;
        this.capacity = newCap;
    }

    public function writeByte(v: Int): Void {
        ensureCapacity(1);
        data.set(writePos, v & 0xFF);
        writePos += 1;
    }

    public function readByte(): Int {
        if (readPos >= writePos) return 0;
        var v = data.get(readPos);
        readPos += 1;
        return v;
    }

    public function writeInt16(v: Int): Void {
        ensureCapacity(2);
        data.set(writePos, v & 0xFF);
        data.set(writePos + 1, (v >> 8) & 0xFF);
        writePos += 2;
    }

    public function readInt16(): Int {
        if (readPos + 2 > writePos) return 0;
        var b0 = data.get(readPos);
        var b1 = data.get(readPos + 1);
        readPos += 2;
        var v = b0 | (b1 << 8);
        if ((v & 0x8000) != 0) {
            v |= 0xFFFF0000;
        }
        return v;
    }

    public function writeInt32(v: Int32): Void {
        ensureCapacity(4);
        data.set(writePos, v & 0xFF);
        data.set(writePos + 1, (v >> 8) & 0xFF);
        data.set(writePos + 2, (v >> 16) & 0xFF);
        data.set(writePos + 3, (v >> 24) & 0xFF);
        writePos += 4;
    }

    public function readInt32(): Int32 {
        if (readPos + 4 > writePos) return 0;
        var b0: Int32 = data.get(readPos);
        var b1: Int32 = data.get(readPos + 1);
        var b2: Int32 = data.get(readPos + 2);
        var b3: Int32 = data.get(readPos + 3);
        readPos += 4;
        return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24);
    }

    public function writeInt64(v: Int64): Void {
        ensureCapacity(8);
        var low: Int32 = v.low;
        var high: Int32 = v.high;
        writeInt32(low);
        writeInt32(high);
    }

    public function readInt64(): Int64 {
        var low = readInt32();
        var high = readInt32();
        return Int64.make(high, low);
    }

    public function writeBool(v: Bool): Void {
        writeByte(v ? 1 : 0);
    }

    public function readBool(): Bool {
        return readByte() != 0;
    }

    public function writeBytes(src: Bytes, offset: Int = 0, length: Int = -1): Void {
        var len = length < 0 ? src.length - offset : length;
        if (len <= 0) return;
        ensureCapacity(len);
        data.blit(writePos, src, offset, len);
        writePos += len;
    }

    public function readBytes(length: Int): Bytes {
        if (length <= 0) return Bytes.alloc(0);
        var avail = writePos - readPos;
        var actual = length < avail ? length : avail;
        var out = Bytes.alloc(actual);
        out.blit(0, data, readPos, actual);
        readPos += actual;
        return out;
    }

    public function writeString(str: String): Void {
        if (str == null) {
            writeInt16(-1);
            return;
        }
        var strBytes = Bytes.ofString(str);
        writeInt16(strBytes.length);
        writeBytes(strBytes, 0, strBytes.length);
    }

    public function readString(): String {
        var len = readInt16();
        if (len < 0) return null;
        if (len == 0) return "";
        var b = readBytes(len);
        return b.getString(0, b.length);
    }

    public function toBytes(): Bytes {
        var out = Bytes.alloc(writePos);
        out.blit(0, data, 0, writePos);
        return out;
    }

    public function getRawBytes(): Bytes {
        return data;
    }

    public function clone(): Buffer {
        var b = new Buffer(this.capacity);
        b.data.blit(0, this.data, 0, this.writePos);
        b.writePos = this.writePos;
        b.readPos = this.readPos;
        return b;
    }
}
