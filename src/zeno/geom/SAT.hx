package zeno.geom;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.math.FPMath;
import zeno.geom.EPA.ContactManifold;

/**
 * Separating Axis Theorem (SAT) collision evaluator.
 * Provides specialized direct intersection tests for boxes and circles,
 * bypassing GJK/EPA simplex expansion for high-frequency common pairs.
 */
class SAT {
    /**
     * Specialized circle-circle collision test.
     */
    public static function testCircleCircle(
        cA: CircleShape, xfA: FPTransform,
        cB: CircleShape, xfB: FPTransform,
        outManifold: ContactManifold
    ): Bool {
        outManifold.isValid = false;
        var diff = xfB.position.sub(xfA.position);
        var distSq = diff.lengthSquared();
        var totalRadius = cA.radius + cB.radius;

        if (distSq > totalRadius * totalRadius) {
            return false;
        }

        var dist = FPMath.sqrt(distSq);
        if (dist < FPNumber.EPSILON) {
            outManifold.normal = FPVector2.RIGHT;
            outManifold.penetration = totalRadius;
            outManifold.point = xfA.position;
        } else {
            outManifold.normal = diff.div(dist);
            outManifold.penetration = totalRadius - dist;
            outManifold.point = xfA.position.add(outManifold.normal.mul(cA.radius));
        }

        outManifold.isValid = true;
        return true;
    }

    /**
     * Specialized box-circle collision test.
     */
    public static function testBoxCircle(
        box: BoxShape, xfBox: FPTransform,
        circle: CircleShape, xfCircle: FPTransform,
        outManifold: ContactManifold
    ): Bool {
        outManifold.isValid = false;

        // Transform circle center into box local coordinate space
        var localCircle = xfBox.inverseTransformPoint(xfCircle.position);

        // Clamp circle center to box extents to find closest point on box
        var closestX = FPMath.clamp(localCircle.x, -box.halfExtents.x, box.halfExtents.x);
        var closestY = FPMath.clamp(localCircle.y, -box.halfExtents.y, box.halfExtents.y);
        var closestLocal = new FPVector2(closestX, closestY);

        var diff = localCircle.sub(closestLocal);
        var distSq = diff.lengthSquared();

        if (distSq > circle.radius * circle.radius) {
            return false;
        }

        var dist = FPMath.sqrt(distSq);
        if (dist < FPNumber.EPSILON) {
            // Circle center inside box: find closest edge
            var dx = box.halfExtents.x - FPMath.abs(localCircle.x);
            var dy = box.halfExtents.y - FPMath.abs(localCircle.y);
            if (dx < dy) {
                var sx = localCircle.x >= FPNumber.ZERO ? FPNumber.ONE : -FPNumber.ONE;
                outManifold.normal = xfBox.transformVector(new FPVector2(sx, FPNumber.ZERO));
                outManifold.penetration = dx + circle.radius;
            } else {
                var sy = localCircle.y >= FPNumber.ZERO ? FPNumber.ONE : -FPNumber.ONE;
                outManifold.normal = xfBox.transformVector(new FPVector2(FPNumber.ZERO, sy));
                outManifold.penetration = dy + circle.radius;
            }
            outManifold.point = xfCircle.position;
        } else {
            var localNorm = diff.div(dist);
            outManifold.normal = xfBox.transformVector(localNorm);
            outManifold.penetration = circle.radius - dist;
            outManifold.point = xfBox.transformPoint(closestLocal);
        }

        outManifold.isValid = true;
        return true;
    }
}
