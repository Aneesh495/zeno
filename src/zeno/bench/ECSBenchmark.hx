package zeno.bench;

import zeno.ecs.World;
import zeno.ecs.ComponentType;
import zeno.ecs.Query;

/**
 * High-throughput microbenchmarks for the archetype ECS engine.
 */
class ECSBenchmark {
    public static function run(): Void {
        BenchmarkRunner.runSuite("Archetype Entity Component System (ECS)", [
            {
                name: "Entity Spawning (10,000 entities)",
                run: function(): Float {
                    var world = new World(16384);
                    var posType = ComponentType.register("Position", 16);
                    var velType = ComponentType.register("Velocity", 16);
                    var count = 10000;

                    var timeUs = BenchmarkRunner.timeMicroseconds(function() {
                        for (i in 0...count) {
                            var e = world.createEntity();
                            world.addComponent(e, posType, {x: i, y: i});
                            world.addComponent(e, velType, {vx: 1, vy: 1});
                        }
                    });

                    return Math.round((count / (timeUs / 1000000.0)));
                }
            },
            {
                name: "Contiguous Query Iteration (10,000 entities)",
                run: function(): Float {
                    var world = new World(16384);
                    var posType = ComponentType.register("Pos", 16);
                    var velType = ComponentType.register("Vel", 16);
                    for (i in 0...10000) {
                        var e = world.createEntity();
                        world.addComponent(e, posType, {x: i, y: i});
                        world.addComponent(e, velType, {vx: 1, vy: 1});
                    }

                    var query = new Query().with(posType).with(velType);
                    world.registerQuery(query);

                    var iterations = 100;
                    var totalProcessed = 0;
                    var timeUs = BenchmarkRunner.timeMicroseconds(function() {
                        for (it in 0...iterations) {
                            query.forEach(function(ent, chunk, row) {
                                totalProcessed++;
                            });
                        }
                    });

                    return Math.round((totalProcessed / (timeUs / 1000000.0)));
                }
            },
            {
                name: "Entity Destruction (10,000 entities)",
                run: function(): Float {
                    var world = new World(16384);
                    var ents = new Array<zeno.ecs.Entity>();
                    for (i in 0...10000) {
                        ents.push(world.createEntity());
                    }

                    var timeUs = BenchmarkRunner.timeMicroseconds(function() {
                        for (e in ents) {
                            world.destroyEntity(e);
                        }
                    });

                    return Math.round((ents.length / (timeUs / 1000000.0)));
                }
            }
        ]);
    }
}
