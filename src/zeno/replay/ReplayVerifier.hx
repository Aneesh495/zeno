package zeno.replay;

import zeno.math.FPNumber;

/**
 * Deterministic Replay Validator.
 * Verifies that replaying an input stream against the initial seed
 * produces bit-exact identical state hashes on every single checkpoint frame.
 */
class ReplayVerifier {
    /**
     * Executes replay verification.
     * @param reader Replay data stream.
     * @param stepSimulation Callback running one tick with inputs: (frame: Int, inputs: Array<Int>) -> Int (returns frame hash)
     * @return True if all recorded checkpoints match replayed state hashes bit-for-bit.
     */
    public static function verify(
        reader: ReplayReader,
        stepSimulation: (frame: Int, inputs: Array<Int>) -> Int
    ): {isValid: Bool, failedFrame: Int, totalChecked: Int} {
        if (reader.header == null) {
            return {isValid: false, failedFrame: -1, totalChecked: 0};
        }

        var totalChecked = 0;
        var count = reader.getFrameCount();

        for (f in 0...count) {
            var rec = reader.frames[f];
            var computedHash = stepSimulation(rec.frame, rec.inputs);

            if (rec.checkpointHash != 0) {
                totalChecked++;
                if (computedHash != rec.checkpointHash) {
                    // Desynchronization detected!
                    return {isValid: false, failedFrame: rec.frame, totalChecked: totalChecked};
                }
            }
        }

        return {isValid: true, failedFrame: -1, totalChecked: totalChecked};
    }
}
