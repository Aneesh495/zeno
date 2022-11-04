package zeno.net;

import haxe.io.Bytes;
import zeno.math.FPRandom;
import zeno.net.Transport.ITransport;

class QueuedPacket {
    public var senderPeerId: Int;
    public var receiverPeerId: Int;
    public var data: Bytes;
    public var deliverTick: Int;

    public function new(sender: Int, receiver: Int, data: Bytes, deliverTick: Int) {
        this.senderPeerId = sender;
        this.receiverPeerId = receiver;
        this.data = data;
        this.deliverTick = deliverTick;
    }
}

/**
 * Virtual in-memory network loopback transport with synthetic chaos injection.
 * Simulates arbitrary packet latency, network jitter, out-of-order delivery,
 * and packet loss rates for deterministic automated testing.
 */
class MemoryTransport implements ITransport {
    public var peerId(default, null): Int;
    public var packetLossRate: Float; // Fraction in [0, 1] of packets to drop
    public var latencyTicks: Int; // Fixed delay in ticks
    public var jitterTicks: Int; // Random +/- variance in latency ticks

    private var currentTick: Int;
    private var inFlightPackets: Array<QueuedPacket>;
    private var receivedPackets: Array<{peerId: Int, data: Bytes}>;
    private var rng: FPRandom;
    private var peers: Array<MemoryTransport>;

    public function new(peerId: Int, latencyTicks: Int = 2, jitterTicks: Int = 1, packetLossRate: Float = 0.0) {
        this.peerId = peerId;
        this.latencyTicks = latencyTicks;
        this.jitterTicks = jitterTicks;
        this.packetLossRate = packetLossRate;
        this.currentTick = 0;
        this.inFlightPackets = new Array<QueuedPacket>();
        this.receivedPackets = new Array<{peerId: Int, data: Bytes}>();
        this.rng = new FPRandom(peerId * 77 + 13);
        this.peers = new Array<MemoryTransport>();
    }

    public function connectPeer(other: MemoryTransport): Void {
        if (peers.indexOf(other) < 0) {
            peers.push(other);
            other.peers.push(this);
        }
    }

    public function send(targetPeerId: Int, data: Bytes): Void {
        // Find recipient transport
        for (peer in peers) {
            if (peer.peerId == targetPeerId) {
                // Evaluate synthetic packet loss
                if (packetLossRate > 0.0) {
                    var roll = (rng.nextInt32() & 0x7FFFFFFF) / 2147483647.0;
                    if (roll < packetLossRate) {
                        // Packet dropped!
                        return;
                    }
                }

                // Compute delivery tick with jitter
                var jitter = (jitterTicks > 0) ? (rng.nextRange(-jitterTicks, jitterTicks)) : 0;
                var delay = latencyTicks + jitter;
                if (delay < 0) delay = 0;
                var deliverAt = currentTick + delay;

                var copy = Bytes.alloc(data.length);
                copy.blit(0, data, 0, data.length);
                peer.inFlightPackets.push(new QueuedPacket(this.peerId, targetPeerId, copy, deliverAt));
                return;
            }
        }
    }

    /**
     * Advances transport clock and delivers packets whose deliverTick has elapsed.
     */
    public function advanceTick(): Void {
        currentTick++;

        var i = inFlightPackets.length - 1;
        while (i >= 0) {
            var p = inFlightPackets[i];
            if (currentTick >= p.deliverTick) {
                receivedPackets.push({peerId: p.senderPeerId, data: p.data});
                inFlightPackets.splice(i, 1);
            }
            i--;
        }
    }

    public function poll(): Array<{peerId: Int, data: Bytes}> {
        var out = receivedPackets.copy();
        while (receivedPackets.length > 0) receivedPackets.pop();
        return out;
    }

    public function close(): Void {
        while (inFlightPackets.length > 0) inFlightPackets.pop();
        while (receivedPackets.length > 0) receivedPackets.pop();
        while (peers.length > 0) peers.pop();
    }
}
