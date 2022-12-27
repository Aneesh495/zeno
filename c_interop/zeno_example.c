/**
 * Zeno Native C Example Integration.
 * Demonstrates Q16.16 fixed-point arithmetic invariants, coordinate transforms,
 * vector operations, and ABI struct alignment for C/C++ game engines.
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "zeno_api.h"

int main(void) {
    printf("================================================================================\n");
    printf("  ZENO: Native C ABI Integration & Verification\n");
    printf("================================================================================\n\n");

    // 1. Verify Q16.16 Fixed-Point representation invariants
    printf("[1/3] Testing Q16.16 fixed-point arithmetic invariants...\n");
    zeno_fp_t one = zeno_fp_from_int(1);
    zeno_fp_t two = zeno_fp_from_int(2);
    zeno_fp_t three = zeno_fp_from_int(3);
    zeno_fp_t half = zeno_fp_from_float(0.5f);

    assert(one == ZENO_FP_ONE);
    assert(half == ZENO_FP_HALF);
    assert(one + two == three);
    assert(zeno_fp_mul(two, three) == zeno_fp_from_int(6));
    assert(zeno_fp_div(zeno_fp_from_int(6), two) == three);
    assert(zeno_fp_mul(half, zeno_fp_from_int(4)) == two);

    printf("  ✓ Q16.16 addition, multiplication, and division verified bit-exact.\n");

    // 2. Verify saturation on overflow
    printf("\n[2/3] Testing fixed-point saturation bounds...\n");
    zeno_fp_t large_a = zeno_fp_from_int(50000);
    zeno_fp_t large_b = zeno_fp_from_int(50000);
    zeno_fp_t sat_prod = zeno_fp_mul(large_a, large_b);
    assert(sat_prod == ZENO_FP_MAX);
    printf("  ✓ Large multiplication overflow saturated to ZENO_FP_MAX (0x%08X).\n", (uint32_t)sat_prod);

    // 3. Vector and Transform operations
    printf("\n[3/3] Testing 2D spatial coordinate transforms...\n");
    zeno_vec2_t p1 = { zeno_fp_from_float(3.0f), zeno_fp_from_float(4.0f) };
    zeno_vec2_t p2 = { zeno_fp_from_float(1.0f), zeno_fp_from_float(2.0f) };
    zeno_vec2_t sum = { p1.x + p2.x, p1.y + p2.y };

    assert(zeno_fp_to_float(sum.x) == 4.0f);
    assert(zeno_fp_to_float(sum.y) == 6.0f);

    zeno_shape_desc_t box_desc;
    box_desc.type = ZENO_SHAPE_BOX;
    box_desc.data.box.half_width = zeno_fp_from_float(1.5f);
    box_desc.data.box.half_height = zeno_fp_from_float(0.75f);
    box_desc.density = zeno_fp_from_float(1.0f);
    box_desc.friction = zeno_fp_from_float(0.3f);
    box_desc.restitution = zeno_fp_from_float(0.1f);

    printf("  ✓ Shape descriptor configured: Box [%.2fx%.2f], density=%.1f\n",
           zeno_fp_to_float(box_desc.data.box.half_width * 2),
           zeno_fp_to_float(box_desc.data.box.half_height * 2),
           zeno_fp_to_float(box_desc.density));

    printf("\n================================================================================\n");
    printf("  ZENO Native C ABI verification completed successfully!\n");
    printf("================================================================================\n");

    return 0;
}
