package zeno.net;

import haxe.io.Bytes;

/**
 * Abstract packet transport interface.
 * Abstracts UDP, WebSockets, or virtual in-memory channels.
 */
interface ITransport {
    public function send(peerId: Int, data: Bytes): Void;
    public function poll(): Array<{peerId: Int, data: Bytes}>;
    public function close(): Void;
}
