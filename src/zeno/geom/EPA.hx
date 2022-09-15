package zeno.geom;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.math.FPMath;
import zeno.geom.Simplex.SupportPoint;

class EdgeInfo {
    public var distance: FPNumber;
    public var normal: FPVector2;
    public var index: Int;

    public function new(dist: FPNumber, norm: FPVector2, idx: Int) {
        this.distance = dist;
        this.normal = norm;
        this.index = idx;
    }
}

/**
 * Contact manifold result extracted by EPA.
 */
class ContactManifold {
    public var normal: FPVector2; // Minimum translation vector normal pointing from A to B
    public var penetration: FPNumber; // Penetration depth (positive scalar)
    public var point: FPVector2; // World space contact point
    public var isValid: Bool;

    public function new() {
        this.normal = FPVector2.ZERO;
        this.penetration = FPNumber.ZERO;
        this.point = FPVector2.ZERO;
        this.isValid = false;
    }
}

/**
 * Expanding Polytope Algorithm (EPA).
 * Expands the GJK simplex to find the exact minimum penetration vector,
 * contact normal, and contact point on the Minkowski boundary.
 */
class EPA {
    public static var MAX_ITERATIONS: Int = 32;

    public static function computeManifold(
        shapeA: Shape, xfA: FPTransform,
        shapeB: Shape, xfB: FPTransform,
        simplex: Simplex,
        outManifold: ContactManifold
    ): Bool {
        outManifold.isValid = false;
        if (simplex.getCount() < 3) return false;

        // Copy simplex points into expanding polytope list
        var polytope = new Array<SupportPoint>();
        for (i in 0...simplex.getCount()) {
            polytope.push(simplex.get(i).clone());
        }

        for (iter in 0...MAX_ITERATIONS) {
            // Find edge closest to the origin
            var closestEdge = findClosestEdge(polytope);
            if (closestEdge == null) break;

            // Search Minkowski difference in the direction of the edge normal
            var support = Minkowski.support(shapeA, xfA, shapeB, xfB, closestEdge.normal);
            var dist = support.point.dot(closestEdge.normal);

            // Convergence condition: support point does not extend significantly past closest edge
            if (dist - closestEdge.distance < FPNumber.fromFloat(0.001)) {
                outManifold.normal = closestEdge.normal;
                outManifold.penetration = dist;

                // Contact point approximation via projection
                var p1 = polytope[closestEdge.index];
                var p2 = polytope[(closestEdge.index + 1) % polytope.length];
                outManifold.point = (p1.pointA.add(p2.pointA)).mul(FPNumber.HALF);
                outManifold.isValid = true;
                return true;
            }

            // Insert new support point into polytope splitting the edge
            polytope.insert(closestEdge.index + 1, support);
        }

        // Fallback to last closest edge
        var fallbackEdge = findClosestEdge(polytope);
        if (fallbackEdge != null) {
            outManifold.normal = fallbackEdge.normal;
            outManifold.penetration = fallbackEdge.distance;
            var p1 = polytope[fallbackEdge.index];
            outManifold.point = p1.pointA;
            outManifold.isValid = true;
            return true;
        }

        return false;
    }

    private static function findClosestEdge(polytope: Array<SupportPoint>): EdgeInfo {
        var minDistance = FPNumber.MAX_VALUE;
        var bestNormal = FPVector2.ZERO;
        var bestIndex = 0;

        var len = polytope.length;
        for (i in 0...len) {
            var p1 = polytope[i].point;
            var p2 = polytope[(i + 1) % len].point;

            var edge = p2.sub(p1);
            // Outward normal: (edge.y, -edge.x)
            var normal = (new FPVector2(edge.y, -edge.x)).normalize();

            var dist = normal.dot(p1);
            if (dist < FPNumber.ZERO) {
                dist = -dist;
                normal = normal.negate();
            }

            if (dist < minDistance) {
                minDistance = dist;
                bestNormal = normal;
                bestIndex = i;
            }
        }

        return new EdgeInfo(minDistance, bestNormal, bestIndex);
    }
}
