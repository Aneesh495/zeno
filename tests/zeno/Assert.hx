package zeno;

/**
 * Lightweight, zero-dependency test assertion framework.
 */
class Assert {
    public static var totalTests: Int = 0;
    public static var totalPassed: Int = 0;
    public static var totalFailed: Int = 0;
    public static var currentSuite: String = "";

    public static function suite(name: String): Void {
        currentSuite = name;
        #if sys
        Sys.println("\n--- [Suite: " + name + "] ---");
        #else
        trace("--- [Suite: " + name + "] ---");
        #end
    }

    public static function isTrue(condition: Bool, message: String): Void {
        totalTests++;
        if (condition) {
            totalPassed++;
            #if sys
            Sys.println("  ✓ PASS: " + message);
            #else
            trace("  PASS: " + message);
            #end
        } else {
            totalFailed++;
            #if sys
            Sys.println("  ✗ FAIL: " + message + " (in " + currentSuite + ")");
            #else
            trace("  FAIL: " + message + " (in " + currentSuite + ")");
            #end
        }
    }

    public static function isFalse(condition: Bool, message: String): Void {
        isTrue(!condition, message);
    }

    public static function equals(expected: Dynamic, actual: Dynamic, message: String): Void {
        isTrue(expected == actual, message + " [Expected: " + expected + ", Got: " + actual + "]");
    }

    public static function nearEquals(expected: Float, actual: Float, tolerance: Float, message: String): Void {
        var diff = Math.abs(expected - actual);
        isTrue(diff <= tolerance, message + " [Expected: " + expected + ", Got: " + actual + ", Diff: " + diff + "]");
    }

    public static function summary(): Bool {
        #if sys
        Sys.println("\n================================================================================");
        Sys.println("TEST SUMMARY: " + totalPassed + " passed, " + totalFailed + " failed (Total: " + totalTests + ")");
        Sys.println("================================================================================\n");
        #else
        trace("TEST SUMMARY: " + totalPassed + " passed, " + totalFailed + " failed (Total: " + totalTests + ")");
        #end
        return totalFailed == 0;
    }

    public static function reset(): Void {
        totalTests = 0;
        totalPassed = 0;
        totalFailed = 0;
    }
}
