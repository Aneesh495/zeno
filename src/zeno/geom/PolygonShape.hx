package zeno.geom;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.math.FPAABB;
import zeno.math.FPMath;
import zeno.geom.Shape.ShapeType;

/**
 * 2D Convex Polygon collision shape.
 * Stores vertices in counter-clockwise winding order with precomputed edge normals.
 */
class PolygonShape extends Shape {
    public var vertices(default, null): Array<FPVector2>;
    public var normals(default, null): Array<FPVector2>;

    public function new(verts: Array<FPVector2>, ?density: FPNumber) {
        super(ShapePolygon, density);
        setVertices(verts);
    }

    public function setVertices(verts: Array<FPVector2>): Void {
        this.vertices = new Array<FPVector2>();
        this.normals = new Array<FPVector2>();

        if (verts == null || verts.length < 3) {
            // Default triangle
            this.vertices.push(new FPVector2(-FPNumber.ONE, -FPNumber.ONE));
            this.vertices.push(new FPVector2(FPNumber.ONE, -FPNumber.ONE));
            this.vertices.push(new FPVector2(FPNumber.ZERO, FPNumber.ONE));
        } else {
            for (v in verts) {
                this.vertices.push(v.clone());
            }
        }

        // Ensure CCW winding
        enforceCounterClockwise();
        computeNormals();
    }

    override public function getSupport(dir: FPVector2, xf: FPTransform): FPVector2 {
        var localDir = xf.inverseTransformVector(dir);

        var bestDot = -FPNumber.MAX_VALUE;
        var bestIdx = 0;

        var len = vertices.length;
        for (i in 0...len) {
            var d = vertices[i].dot(localDir);
            if (d > bestDot) {
                bestDot = d;
                bestIdx = i;
            }
        }

        return xf.transformPoint(vertices[bestIdx]);
    }

    override public function computeAABB(xf: FPTransform): FPAABB {
        var minX = FPNumber.MAX_VALUE;
        var minY = FPNumber.MAX_VALUE;
        var maxX = -FPNumber.MAX_VALUE;
        var maxY = -FPNumber.MAX_VALUE;

        var len = vertices.length;
        for (i in 0...len) {
            var wp = xf.transformPoint(vertices[i]);
            minX = FPMath.min(minX, wp.x);
            minY = FPMath.min(minY, wp.y);
            maxX = FPMath.max(maxX, wp.x);
            maxY = FPMath.max(maxY, wp.y);
        }

        return FPAABB.make(minX, minY, maxX, maxY);
    }

    override public function computeMass(density: FPNumber): {mass: FPNumber, inertia: FPNumber} {
        // Green's theorem polygon area and centroid
        var area = FPNumber.ZERO;
        var center = FPVector2.ZERO;
        var inertia = FPNumber.ZERO;

        var len = vertices.length;
        for (i in 0...len) {
            var p1 = vertices[i];
            var p2 = vertices[(i + 1) % len];

            var cross = p1.cross(p2);
            var triangleArea = cross * FPNumber.HALF;
            area = area + triangleArea;

            // Area moment of inertia
            var intx2 = (p1.x * p1.x) + (p1.x * p2.x) + (p2.x * p2.x);
            var inty2 = (p1.y * p1.y) + (p1.y * p2.y) + (p2.y * p2.y);
            inertia = inertia + ((cross * (intx2 + inty2)) / FPNumber.fromInt(12));
        }

        var mass = density * area;
        inertia = density * inertia;

        return {mass: mass > FPNumber.ZERO ? mass : FPNumber.ONE, inertia: inertia > FPNumber.ZERO ? inertia : FPNumber.ONE};
    }

    private function enforceCounterClockwise(): Void {
        // Signed area test
        var signedArea = FPNumber.ZERO;
        var len = vertices.length;
        for (i in 0...len) {
            var v1 = vertices[i];
            var v2 = vertices[(i + 1) % len];
            signedArea = signedArea + (v1.x * v2.y - v2.x * v1.y);
        }

        if (signedArea < FPNumber.ZERO) {
            // Reverse vertices to enforce CCW
            var reversed = new Array<FPVector2>();
            var i = vertices.length - 1;
            while (i >= 0) {
                reversed.push(vertices[i]);
                i--;
            }
            this.vertices = reversed;
        }
    }

    private function computeNormals(): Void {
        var len = vertices.length;
        for (i in 0...len) {
            var v1 = vertices[i];
            var v2 = vertices[(i + 1) % len];
            var edge = v2.sub(v1);
            // Outward normal: (edge.y, -edge.x) normalized
            var normal = (new FPVector2(edge.y, -edge.x)).normalize();
            normals.push(normal);
        }
    }

    override public function clone(): Shape {
        return new PolygonShape(vertices, density);
    }
}
