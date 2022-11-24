package zeno.bench;

import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPTransform;
import zeno.geom.CircleShape;
import zeno.geom.BoxShape;
import zeno.geom.GJK;
import zeno.geom.EPA;
import zeno.geom.Simplex;
import zeno.spatial.DynamicBVH;
import zeno.physics.PhysicsWorld;
import zeno.physics.RigidBody;
import zeno.physics.Collider;
import zeno.physics.BodyType;

/**
 * Microbenchmarks for geometry narrowphase, BVH spatial indexing, and physics steps.
 */
class PhysicsBenchmark {
    public static function run(): Void {
        BenchmarkRunner.runSuite("Computational Geometry & Physics Engine", [
            {
                name: "GJK Convex Collision Queries (10,000 pairs)",
                run: function(): Float {
                    var boxA = BoxShape.make(FPNumber.fromInt(2), FPNumber.fromInt(2));
                    var boxB = BoxShape.make(FPNumber.fromInt(2), FPNumber.fromInt(2));
                    var xfA = new FPTransform(FPVector2.ZERO, FPNumber.ZERO);
                    var xfB = new FPTransform(new FPVector2(FPNumber.fromFloat(1.5), FPNumber.ZERO), FPNumber.ZERO);
                    var simplex = new Simplex();
                    var count = 10000;

                    var timeUs = BenchmarkRunner.timeMicroseconds(function() {
                        for (i in 0...count) {
                            GJK.testIntersection(boxA, xfA, boxB, xfB, simplex);
                        }
                    });

                    return Math.round((count / (timeUs / 1000000.0)));
                }
            },
            {
                name: "Dynamic BVH Spatial Queries (500 leaves, 5,000 queries)",
                run: function(): Float {
                    var bvh = new DynamicBVH(512);
                    for (i in 0...500) {
                        var minX = FPNumber.fromInt(i % 50);
                        var minY = FPNumber.fromInt(Std.int(i / 50));
                        var aabb = zeno.math.FPAABB.make(minX, minY, minX + FPNumber.ONE, minY + FPNumber.ONE);
                        bvh.insert(zeno.ecs.Entity.make(i + 1, 1), aabb);
                    }

                    var queryAABB = zeno.math.FPAABB.make(FPNumber.fromInt(10), FPNumber.fromInt(5), FPNumber.fromInt(15), FPNumber.fromInt(10));
                    var count = 5000;
                    var hits = 0;

                    var timeUs = BenchmarkRunner.timeMicroseconds(function() {
                        for (i in 0...count) {
                            bvh.query(queryAABB, function(ent) {
                                hits++;
                                return true;
                            });
                        }
                    });

                    return Math.round((count / (timeUs / 1000000.0)));
                }
            },
            {
                name: "Full Physics Step (100 rigid bodies, 30 ticks)",
                run: function(): Float {
                    var pWorld = new PhysicsWorld();
                    // Ground
                    var groundShape = BoxShape.make(FPNumber.fromInt(100), FPNumber.fromInt(2));
                    var groundBody = new RigidBody(BodyStatic, new FPVector2(FPNumber.ZERO, FPNumber.fromInt(-5)));
                    pWorld.addBody(zeno.ecs.Entity.make(1, 1), groundBody, new Collider(groundShape));

                    // Dynamic bodies
                    for (i in 0...100) {
                        var shape = new CircleShape(FPNumber.fromFloat(0.5));
                        var x = FPNumber.fromInt((i % 10) * 2 - 10);
                        var y = FPNumber.fromInt(5 + Std.int(i / 10) * 2);
                        var body = new RigidBody(BodyDynamic, new FPVector2(x, y));
                        pWorld.addBody(zeno.ecs.Entity.make(i + 2, 1), body, new Collider(shape));
                    }

                    var dt = FPNumber.ONE / FPNumber.fromInt(60);
                    var ticks = 30;

                    var timeUs = BenchmarkRunner.timeMicroseconds(function() {
                        for (t in 0...ticks) {
                            pWorld.step(dt);
                        }
                    });

                    return Math.round((ticks / (timeUs / 1000000.0)));
                }
            }
        ]);
    }
}
