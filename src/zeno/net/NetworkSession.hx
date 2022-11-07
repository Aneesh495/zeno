package zeno.net;

import haxe.io.Bytes;
import zeno.core.Buffer;
import zeno.math.FPNumber;
import zeno.rollback.RollbackManager;
import zeno.net.Transport.ITransport;

/**
 * High-performance Peer-to-Peer Rollback Network Session.
 * Synchronizes client inputs, regulates frame pacing, and handles transparent rollback recovery.
 */
class NetworkSession {
    public var localPlayer: Int;
    public var remotePlayer: Int;

    private var transport: ITransport;
    private var rollbackManager: RollbackManager;
    private var jitterBuffer: JitterBuffer;
    private var timeSync: TimeSync;
    private var frameAdvantage: FrameAdvantage;
    private var packetSequence: Int;

    public function new(
        localPlayer: Int,
        remotePlayer: Int,
        transport: ITransport,
        rollbackManager: RollbackManager
    ) {
        this.localPlayer = localPlayer;
        this.remotePlayer = remotePlayer;
        this.transport = transport;
        this.rollbackManager = rollbackManager;
        this.jitterBuffer = new JitterBuffer();
        this.timeSync = new TimeSync();
        this.frameAdvantage = new FrameAdvantage();
        this.packetSequence = 0;
    }

    public inline function getJitterBuffer(): JitterBuffer return jitterBuffer;
    public inline function getTimeSync(): TimeSync return timeSync;
    public inline function getRollbackManager(): RollbackManager return rollbackManager;

    /**
     * Polls incoming network packets, parses inputs, and feeds them into rollback manager.
     */
    public function pollNetwork(dt: FPNumber): Void {
        var packets = transport.poll();
        for (item in packets) {
            var buf = Buffer.wrap(item.data);
            var packet = InputPacket.deserialize(buf);
            if (packet != null) {
                jitterBuffer.pushPacket(packet);

                // Ingest latest confirmed frame
                rollbackManager.onRemoteInput(remotePlayer, packet.targetFrame, packet.currentInput, dt);

                // Update clock synchronization
                timeSync.updateFrames(rollbackManager.currentFrame, packet.targetFrame);
            }
        }
    }

    /**
     * Broadcasts local input for the specified frame to remote peer.
     */
    public function sendInput(frame: Int, inputBits: Int): Void {
        // Collect past 3 trailing inputs from history for loss redundancy
        var trailing = new Array<Int>();
        for (i in 1...4) {
            var pastFrame = frame - i;
            var pastInput = (pastFrame >= 0) ? rollbackManager.getInputHistory().getInput(localPlayer, pastFrame) : 0;
            trailing.push(pastInput);
        }

        var packet = new InputPacket(packetSequence++, frame, inputBits, trailing);
        var buf = packet.serialize();
        transport.send(remotePlayer, buf.toBytes());
    }

    /**
     * Advances simulation tick with adaptive frame pacing.
     * @return True if a simulation step was executed, false if throttled.
     */
    public function step(dt: FPNumber, stepWorld: (dt: FPNumber) -> Void): Bool {
        // Check frame pacing action
        var adv = timeSync.getFrameAdvantage();
        var action = frameAdvantage.getRecommendedAction(adv);

        if (action < 0) {
            // Throttling: skip simulation tick this frame to let remote catch up
            return false;
        }

        // Advance simulation
        rollbackManager.advanceFrame(dt, stepWorld);

        if (action > 0) {
            // Acceleration: execute catch-up tick
            rollbackManager.advanceFrame(dt, stepWorld);
        }

        return true;
    }
}
