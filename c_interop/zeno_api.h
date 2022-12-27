/**
 * Zeno Native C Foreign Function Interface (FFI) Header.
 * Provides C99-compatible type definitions, fixed-point math helpers,
 * and standard ABI bindings for integrating Zeno into native C/C++ runtimes.
 */

#ifndef ZENO_API_H
#define ZENO_API_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

#define ZENO_FP_SHIFT 16
#define ZENO_FP_ONE (1 << ZENO_FP_SHIFT)
#define ZENO_FP_HALF (1 << (ZENO_FP_SHIFT - 1))
#define ZENO_FP_MAX INT32_MAX
#define ZENO_FP_MIN INT32_MIN

/**
 * 32-bit signed fixed-point integer (Q16.16 representation).
 * 1 sign bit, 15 integer bits, 16 fractional bits.
 */
typedef int32_t zeno_fp_t;

/**
 * Generational entity handle (lower 20 bits index, upper 12 bits generation).
 */
typedef uint32_t zeno_entity_t;

/**
 * 2D fixed-point vector.
 */
typedef struct {
    zeno_fp_t x;
    zeno_fp_t y;
} zeno_vec2_t;

/**
 * 2D spatial coordinate transform (position + orientation angle).
 */
typedef struct {
    zeno_vec2_t position;
    zeno_fp_t angle;
} zeno_transform_t;

/**
 * Axis-Aligned Bounding Box (AABB).
 */
typedef struct {
    zeno_vec2_t lower_bound;
    zeno_vec2_t upper_bound;
} zeno_aabb_t;

/**
 * Kinematic body classification.
 */
typedef enum {
    ZENO_BODY_STATIC = 0,
    ZENO_BODY_KINEMATIC = 1,
    ZENO_BODY_DYNAMIC = 2
} zeno_body_type_t;

/**
 * Geometric shape primitive category.
 */
typedef enum {
    ZENO_SHAPE_CIRCLE = 0,
    ZENO_SHAPE_BOX = 1,
    ZENO_SHAPE_CAPSULE = 2,
    ZENO_SHAPE_POLYGON = 3
} zeno_shape_type_t;

/**
 * Geometric shape construction descriptor.
 */
typedef struct {
    zeno_shape_type_t type;
    union {
        struct {
            zeno_fp_t radius;
        } circle;
        struct {
            zeno_fp_t half_width;
            zeno_fp_t half_height;
        } box;
    } data;
    zeno_fp_t density;
    zeno_fp_t friction;
    zeno_fp_t restitution;
} zeno_shape_desc_t;

/**
 * Simulation snapshot header for telemetry and verification.
 */
typedef struct {
    uint32_t frame;
    uint32_t checksum;
    uint32_t entity_count;
    uint32_t rollbacks_executed;
    uint32_t frames_resimulated;
} zeno_snapshot_info_t;

/* Opaque pointer to internal simulation engine instance */
typedef struct zeno_engine zeno_engine_t;

/* ========================================================================= */
/* Fixed-Point Inline Math Helpers                                           */
/* ========================================================================= */

static inline zeno_fp_t zeno_fp_from_int(int32_t val) {
    return val << ZENO_FP_SHIFT;
}

static inline int32_t zeno_fp_to_int(zeno_fp_t val) {
    return val >> ZENO_FP_SHIFT;
}

static inline zeno_fp_t zeno_fp_from_float(float val) {
    return (zeno_fp_t)(val * 65536.0f);
}

static inline float zeno_fp_to_float(zeno_fp_t val) {
    return ((float)val) / 65536.0f;
}

static inline zeno_fp_t zeno_fp_mul(zeno_fp_t a, zeno_fp_t b) {
    int64_t prod = ((int64_t)a * (int64_t)b) >> ZENO_FP_SHIFT;
    if (prod > ZENO_FP_MAX) return ZENO_FP_MAX;
    if (prod < ZENO_FP_MIN) return ZENO_FP_MIN;
    return (zeno_fp_t)prod;
}

static inline zeno_fp_t zeno_fp_div(zeno_fp_t a, zeno_fp_t b) {
    if (b == 0) return (a >= 0) ? ZENO_FP_MAX : ZENO_FP_MIN;
    int64_t quot = (((int64_t)a) << ZENO_FP_SHIFT) / (int64_t)b;
    if (quot > ZENO_FP_MAX) return ZENO_FP_MAX;
    if (quot < ZENO_FP_MIN) return ZENO_FP_MIN;
    return (zeno_fp_t)quot;
}

/* ========================================================================= */
/* Core Engine C ABI Export Signatures                                       */
/* ========================================================================= */

zeno_engine_t* zeno_create(uint32_t seed, uint32_t tick_rate_hz);
void zeno_destroy(zeno_engine_t* engine);

zeno_entity_t zeno_spawn_body(
    zeno_engine_t* engine,
    zeno_body_type_t body_type,
    const zeno_shape_desc_t* shape_desc,
    zeno_vec2_t position,
    zeno_fp_t angle
);

void zeno_submit_local_input(zeno_engine_t* engine, uint32_t player_index, uint32_t input_mask);
bool zeno_submit_remote_input(zeno_engine_t* engine, uint32_t player_index, uint32_t frame, uint32_t input_mask);

void zeno_step(zeno_engine_t* engine);
void zeno_get_snapshot_info(const zeno_engine_t* engine, zeno_snapshot_info_t* out_info);
bool zeno_get_body_transform(const zeno_engine_t* engine, zeno_entity_t entity, zeno_transform_t* out_transform);

#ifdef __cplusplus
}
#endif

#endif /* ZENO_API_H */
