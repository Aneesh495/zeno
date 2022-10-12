package zeno.physics;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.math.FPMath;
import zeno.geom.Shape;
import zeno.geom.GJK;
import zeno.geom.Simplex;

/**
 * Continuous Collision Detection (CCD) via Conservative Advancement.
 * Prevents high-speed dynamic bodies from tunneling through thin obstacles
 * by calculating the exact Time of Impact (TOI) within the simulation time step.
 */
class ContinuousCollision {
    public static var MAX_ITERATIONS: Int = 20;

    /**
     * Computes the Time of Impact (TOI) fraction in [0, 1] for moving body A against body B.
     * @return TOI fraction (1.0 means no collision occurred during the step).
     */
    public static function computeTimeOfImpact(
        shapeA: Shape, xfA: FPTransform, velA: FPVector2,
        shapeB: Shape, xfB: FPTransform, velB: FPVector2,
        dt: FPNumber
    ): FPNumber {
        var t = FPNumber.ZERO;
        var simplex = new Simplex();

        // Relative velocity of A with respect to B: vA - vB
        var vRel = velA.sub(velB);
        var speed = vRel.length();
        if (speed < FPNumber.EPSILON) {
            return FPNumber.ONE;
        }

        var currentXfA = xfA.clone();
        var currentXfB = xfB.clone();
        var targetDistanceTolerance = FPNumber.fromFloat(0.01);

        for (iter in 0...MAX_ITERATIONS) {
            // Update transforms to current time t
            currentXfA.position = xfA.position.add(velA.mul(t * dt));
            currentXfB.position = xfB.position.add(velB.mul(t * dt));

            // Test intersection at current position
            if (GJK.testIntersection(shapeA, currentXfA, shapeB, currentXfB, simplex)) {
                return t;
            }

            // Estimate distance from simplex
            var d = FPNumber.ONE;
            if (simplex.getCount() > 0) {
                var p = simplex.get(0).point;
                d = p.length();
            }

            if (d < targetDistanceTolerance) {
                return t;
            }

            // Conservative time step: dt_adv = d / (speed * dt)
            var deltaT = d / (speed * dt);
            if (deltaT < FPNumber.fromFloat(0.001)) {
                deltaT = FPNumber.fromFloat(0.001);
            }

            t = t + deltaT;
            if (t >= FPNumber.ONE) {
                return FPNumber.ONE;
            }
        }

        return FPNumber.ONE;
    }
}
