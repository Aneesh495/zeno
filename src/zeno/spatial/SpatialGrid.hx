package zeno.spatial;

import haxe.ds.IntMap;
import zeno.math.FPNumber;
import zeno.math.FPVector2;
import zeno.math.FPAABB;
import zeno.ecs.Entity;

/**
 * 2D Spatial Hash Grid for high-density uniform collision filtering.
 * Hashes spatial 2D cells into discrete bucket arrays in O(1) time.
 */
class SpatialGrid {
    private var cellSize: FPNumber;
    private var invCellSize: FPNumber;
    private var buckets: IntMap<Array<Entity>>;

    private static inline var PRIME1: Int = 73856093;
    private static inline var PRIME2: Int = 19349663;

    public function new(cellSize: FPNumber) {
        this.cellSize = cellSize > FPNumber.ZERO ? cellSize : FPNumber.ONE;
        this.invCellSize = FPNumber.ONE / this.cellSize;
        this.buckets = new IntMap<Array<Entity>>();
    }

    public function insert(entity: Entity, aabb: FPAABB): Void {
        var minX = (aabb.lowerBound.x * invCellSize).toInt();
        var minY = (aabb.lowerBound.y * invCellSize).toInt();
        var maxX = (aabb.upperBound.x * invCellSize).toInt();
        var maxY = (aabb.upperBound.y * invCellSize).toInt();

        for (x in minX...maxX + 1) {
            for (y in minY...maxY + 1) {
                var hash = hashCell(x, y);
                var list = buckets.get(hash);
                if (list == null) {
                    list = new Array<Entity>();
                    buckets.set(hash, list);
                }
                list.push(entity);
            }
        }
    }

    public function query(aabb: FPAABB, outEntities: Array<Entity>): Void {
        var minX = (aabb.lowerBound.x * invCellSize).toInt();
        var minY = (aabb.lowerBound.y * invCellSize).toInt();
        var maxX = (aabb.upperBound.x * invCellSize).toInt();
        var maxY = (aabb.upperBound.y * invCellSize).toInt();

        for (x in minX...maxX + 1) {
            for (y in minY...maxY + 1) {
                var hash = hashCell(x, y);
                var list = buckets.get(hash);
                if (list != null) {
                    for (ent in list) {
                        if (outEntities.indexOf(ent) < 0) {
                            outEntities.push(ent);
                        }
                    }
                }
            }
        }
    }

    public function clear(): Void {
        buckets = new IntMap<Array<Entity>>();
    }

    private static inline function hashCell(x: Int, y: Int): Int {
        return ((x * PRIME1) ^ (y * PRIME2)) & 0x7FFFFFFF;
    }
}
