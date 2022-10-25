package zeno.rollback;

import haxe.ds.IntMap;

class FrameInput {
    public var inputBits: Int;
    public var isConfirmed: Bool;

    public function new(bits: Int, confirmed: Bool) {
        this.inputBits = bits;
        this.isConfirmed = confirmed;
    }
}

/**
 * Multi-player input history tracking confirmed and predicted inputs across frames.
 * Implements input prediction (speculative execution) and tracks unconfirmed frame horizons.
 */
class InputHistory {
    public var playerCount(default, null): Int;

    // playerIndex -> (frameIndex -> FrameInput)
    private var history: Array<IntMap<FrameInput>>;
    private var lastConfirmedFrame: Array<Int>;

    public function new(playerCount: Int = 2) {
        this.playerCount = playerCount > 0 ? playerCount : 2;
        this.history = new Array<IntMap<FrameInput>>();
        this.lastConfirmedFrame = new Array<Int>();

        for (i in 0...playerCount) {
            history.push(new IntMap<FrameInput>());
            lastConfirmedFrame.push(-1);
        }
    }

    public function setInput(player: Int, frame: Int, inputBits: Int, isConfirmed: Bool): Void {
        if (player < 0 || player >= playerCount) return;

        var map = history[player];
        var existing = map.get(frame);
        if (existing == null) {
            map.set(frame, new FrameInput(inputBits, isConfirmed));
        } else {
            existing.inputBits = inputBits;
            existing.isConfirmed = isConfirmed;
        }

        if (isConfirmed && frame > lastConfirmedFrame[player]) {
            lastConfirmedFrame[player] = frame;
        }
    }

    /**
     * Retrieves the input for a player at a frame.
     * If unpopulated, predicts the input by repeating the last confirmed input.
     */
    public function getInput(player: Int, frame: Int): Int {
        if (player < 0 || player >= playerCount) return 0;

        var map = history[player];
        var entry = map.get(frame);
        if (entry != null) {
            return entry.inputBits;
        }

        // Predict by repeating last known frame input
        return predictInput(player, frame);
    }

    public function isConfirmed(player: Int, frame: Int): Bool {
        if (player < 0 || player >= playerCount) return false;
        var entry = history[player].get(frame);
        return entry != null && entry.isConfirmed;
    }

    public function predictInput(player: Int, frame: Int): Int {
        var lastFrame = lastConfirmedFrame[player];
        if (lastFrame >= 0) {
            var lastEntry = history[player].get(lastFrame);
            if (lastEntry != null) {
                // Store predicted input
                history[player].set(frame, new FrameInput(lastEntry.inputBits, false));
                return lastEntry.inputBits;
            }
        }
        history[player].set(frame, new FrameInput(0, false));
        return 0;
    }

    public function getLastConfirmedFrame(player: Int): Int {
        if (player < 0 || player >= playerCount) return -1;
        return lastConfirmedFrame[player];
    }

    public function clear(): Void {
        for (i in 0...playerCount) {
            history[i] = new IntMap<FrameInput>();
            lastConfirmedFrame[i] = -1;
        }
    }
}
