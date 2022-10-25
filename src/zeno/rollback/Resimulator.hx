package zeno.rollback;

import zeno.math.FPNumber;

/**
 * Resimulation execution engine.
 * Restores world state to a historical frame and fast-forwards the simulation loop
 * back to the current live frame, reconciling predicted and confirmed remote inputs.
 */
class Resimulator {
    private var buffer: RollbackBuffer;
    private var inputHistory: InputHistory;
    private var stepCallback: (frame: Int, dt: FPNumber) -> Void;
    private var restoreCallback: (snapshot: Snapshot) -> Void;

    public function new(
        buffer: RollbackBuffer,
        inputHistory: InputHistory,
        stepCallback: (frame: Int, dt: FPNumber) -> Void,
        restoreCallback: (snapshot: Snapshot) -> Void
    ) {
        this.buffer = buffer;
        this.inputHistory = inputHistory;
        this.stepCallback = stepCallback;
        this.restoreCallback = restoreCallback;
    }

    /**
     * Executes rollback from rollbackFrame up to currentFrame.
     * @param rollbackFrame Historical target frame to rewind to.
     * @param currentFrame Live simulation frame to resimulate up to.
     * @param dt Fixed delta time per step.
     * @return Number of frames resimulated.
     */
    public function resimulate(rollbackFrame: Int, currentFrame: Int, dt: FPNumber): Int {
        if (rollbackFrame >= currentFrame) return 0;

        // Retrieve baseline historical snapshot
        var snapshot = buffer.getSnapshot(rollbackFrame);
        if (snapshot == null) {
            // Cannot roll back further than available history
            return 0;
        }

        // 1. Rewind world state
        restoreCallback(snapshot);

        // 2. Fast-forward resimulation loop
        var framesResimulated = 0;
        for (f in rollbackFrame...currentFrame) {
            stepCallback(f, dt);
            framesResimulated++;
        }

        return framesResimulated;
    }
}
