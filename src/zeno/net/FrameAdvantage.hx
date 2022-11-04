package zeno.net;

/**
 * Dynamic frame pacing regulator.
 * Calculates frame pacing adjustments to throttle or accelerate local tick rate,
 * keeping peers closely synchronized and bounding maximum rollback depth.
 */
class FrameAdvantage {
    public var maxFrameAdvantage: Int; // Max frames local can run ahead before throttling (e.g. 4)
    public var minFrameAdvantage: Int; // Frames behind before acceleration (e.g. -4)

    public function new(maxAdvantage: Int = 4, minAdvantage: Int = -4) {
        this.maxFrameAdvantage = maxAdvantage;
        this.minFrameAdvantage = minAdvantage;
    }

    /**
     * Recommends pacing action:
     * - Returns 0: normal step (1 tick)
     * - Returns -1: throttle (pause this frame, 0 ticks)
     * - Returns +1: catch up (double step, 2 ticks)
     */
    public function getRecommendedAction(frameAdvantage: Int): Int {
        if (frameAdvantage > maxFrameAdvantage) {
            // Running too far ahead of remote: throttle local simulation
            return -1;
        } else if (frameAdvantage < minFrameAdvantage) {
            // Falling behind: accelerate to catch up
            return 1;
        }
        return 0;
    }
}
