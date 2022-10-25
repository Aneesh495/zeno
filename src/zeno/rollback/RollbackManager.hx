package zeno.rollback;

import zeno.math.FPNumber;

/**
 * High-level Rollback & Speculative Synchronization Manager.
 * Orchestrates input queues, state snapshotting, misprediction detection,
 * and seamless sub-millisecond resimulation loops.
 */
class RollbackManager {
    public var currentFrame(default, null): Int;
    public var maxRollbackFrames: Int;

    private var buffer: RollbackBuffer;
    private var inputHistory: InputHistory;
    private var resimulator: Resimulator;
    private var captureCallback: (frame: Int) -> Snapshot;

    private var totalRollbacksExecuted: Int;
    private var totalFramesResimulated: Int;

    public function new(
        playerCount: Int,
        maxRollbackFrames: Int = 64,
        captureCallback: (frame: Int) -> Snapshot,
        restoreCallback: (snapshot: Snapshot) -> Void,
        stepCallback: (frame: Int, dt: FPNumber) -> Void
    ) {
        this.currentFrame = 0;
        this.maxRollbackFrames = maxRollbackFrames;
        this.captureCallback = captureCallback;

        this.buffer = new RollbackBuffer(maxRollbackFrames * 2);
        this.inputHistory = new InputHistory(playerCount);
        this.resimulator = new Resimulator(buffer, inputHistory, stepCallback, restoreCallback);

        this.totalRollbacksExecuted = 0;
        this.totalFramesResimulated = 0;
    }

    public inline function getBuffer(): RollbackBuffer return buffer;
    public inline function getInputHistory(): InputHistory return inputHistory;
    public inline function getTotalRollbacks(): Int return totalRollbacksExecuted;
    public inline function getTotalResimulatedFrames(): Int return totalFramesResimulated;

    /**
     * Submits local player input for the current frame.
     */
    public function setLocalInput(playerIndex: Int, inputBits: Int): Void {
        inputHistory.setInput(playerIndex, currentFrame, inputBits, true);
    }

    /**
     * Ingests confirmed remote player input from the network.
     * If the remote input arrived late and differs from our local prediction,
     * immediately triggers a rollback and resimulates to the current frame.
     */
    public function onRemoteInput(playerIndex: Int, frame: Int, inputBits: Int, dt: FPNumber): Bool {
        if (frame > currentFrame) {
            // Future frame input: buffer it
            inputHistory.setInput(playerIndex, frame, inputBits, true);
            return false;
        }

        var predictedInput = inputHistory.getInput(playerIndex, frame);
        var wasConfirmed = inputHistory.isConfirmed(playerIndex, frame);

        // Update history with confirmed input
        inputHistory.setInput(playerIndex, frame, inputBits, true);

        // Misprediction test: if input differed from prediction on a past frame
        if (frame < currentFrame && (!wasConfirmed && predictedInput != inputBits)) {
            var rollbackHorizon = currentFrame - maxRollbackFrames;
            var targetFrame = (frame < rollbackHorizon) ? rollbackHorizon : frame;

            var resimCount = resimulator.resimulate(targetFrame, currentFrame, dt);
            totalRollbacksExecuted++;
            totalFramesResimulated += resimCount;
            return true;
        }

        return false;
    }

    /**
     * Advances simulation frame: captures baseline snapshot, steps world, and advances clock.
     */
    public function advanceFrame(dt: FPNumber, stepWorld: (dt: FPNumber) -> Void): Snapshot {
        // 1. Capture snapshot before or at start of frame
        var snapshot = captureCallback(currentFrame);
        snapshot.checksum = StateHasher.hashSnapshot(snapshot);
        buffer.saveSnapshot(snapshot);

        // 2. Step the world simulation
        stepWorld(dt);

        // 3. Increment frame clock
        currentFrame++;

        return snapshot;
    }

    public function clear(): Void {
        buffer.clear();
        inputHistory.clear();
        currentFrame = 0;
        totalRollbacksExecuted = 0;
        totalFramesResimulated = 0;
    }
}
