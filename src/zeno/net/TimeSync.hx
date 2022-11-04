package zeno.net;

import zeno.math.FPNumber;
import zeno.math.FPMath;

/**
 * Round-trip time (RTT) estimator and clock drift tracker.
 * Employs Exponential Moving Average (EMA) to filter network jitter.
 */
class TimeSync {
    public var rtt(default, null): FPNumber; // Round Trip Time in seconds
    public var rttJitter(default, null): FPNumber; // Mean deviation of RTT
    public var localFrame: Int;
    public var remoteFrame: Int;

    private var alpha: FPNumber; // EMA smoothing factor (e.g. 0.125)

    public function new() {
        this.rtt = FPNumber.fromFloat(0.05); // Initial 50ms estimate
        this.rttJitter = FPNumber.fromFloat(0.01);
        this.localFrame = 0;
        this.remoteFrame = 0;
        this.alpha = FPNumber.fromFloat(0.125);
    }

    /**
     * Updates RTT estimate upon receiving a ping reply or timestamped packet.
     */
    public function updateRTT(measuredRTT: FPNumber): Void {
        if (measuredRTT <= FPNumber.ZERO) return;

        var diff = FPMath.abs(measuredRTT - rtt);
        rttJitter = rttJitter + (diff - rttJitter) * alpha;
        rtt = rtt + (measuredRTT - rtt) * alpha;
    }

    /**
     * Updates observed frame counters.
     */
    public function updateFrames(local: Int, remote: Int): Void {
        this.localFrame = local;
        this.remoteFrame = remote;
    }

    /**
     * Calculates the frame advantage: localFrame - remoteFrame.
     * Positive indicates local client is running ahead of remote peer.
     */
    public inline function getFrameAdvantage(): Int {
        return localFrame - remoteFrame;
    }
}
