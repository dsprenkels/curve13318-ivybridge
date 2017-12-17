#include "fe_convert.h"
#include "ge.h"
#include <stdbool.h>

static bool ge_affine_point_on_curve(ge p)
{
    // Use the general curve equation to check if this point is on the curve
    // y^2 = x^3 - 3*x + 13318
    fe10 p0, p1, lhs, rhs, t0;
    fe10_frozen result;
    convert_fe12_to_fe10(p0, p[0]);
    convert_fe12_to_fe10(p1, p[1]);
    fe10_square(lhs, p1);  // y^2
    fe10_square(t0, p0);   // x^2
    fe10_mul(rhs, t0, p0); // x^3
    fe10_zero(t0);           // 0
    fe10_add2p(t0);          // 0
    fe10_sub(t0, t0, p0);  // -x
    fe10_add(rhs, rhs, t0);  // x^3 - x
    fe10_add(rhs, rhs, t0);  // x^3 - 2*x
    fe10_add(rhs, rhs, t0);  // x^3 - 3*x
    fe10_add_b(rhs);         // x^3 - 3*x + 13318
    fe10_carry(rhs);
    fe10_add2p(lhs);         // Still y^2
    fe10_sub(lhs, lhs, rhs); // (==0) or (!=0) mod p
    fe10_carry(lhs);
    fe10_reduce(result, lhs);        // 0 or !0

    uint64_t nonzero = 0;
    for (unsigned int i = 0; i < 5; i++) nonzero |= lhs[i];
    return nonzero == 0;
}

int ge_frombytes(ge p, const uint8_t *s)
{
    fe12_frombytes(p[0], &s[0]);
    fe12_frombytes(p[1], &s[32]);

    // Handle point at infinity encoded by (0, 0)
    uint64_t infinity = 1;
    for (unsigned int i = 0; i < 12; i++) infinity &= p[0][i] == 0;
    for (unsigned int i = 0; i < 12; i++) infinity &= p[1][i] == 0;
    uint64_t not_infinity = !infinity;

    // Set y to 1 if we are at the point at infinity
    p[1][0] = 1 * infinity;
    // Initialize z to 1 (or 0 if infinity)
    p[2][0] = 1 * not_infinity;
    for (unsigned int i = 1; i < 12; i++) p[2][i] = 0;

    // Check if this point is valid
    if (not_infinity & !ge_affine_point_on_curve(p)) return -1;
    return 0;
}

#include "ge.h"

void ge_tobytes(uint8_t *s, ge p)
{
    /*
    This function actually deals with the point at infinity, encoded as (0, 0).
    Namely, if `z` (`p[2]`) is zero, because of the implementation of
    `fe10_invert`, `z_inverse` will also be 0. And so, the coordinates that are
    encoded into `s` are 0.
    */
    fe10 x, y, z, x_affine, y_affine, z_inverse;

    // Move to fe10, because 4x parallelization is not possible anymore
    convert_fe12_to_fe10(x, p[0]);
    convert_fe12_to_fe10(y, p[1]);
    convert_fe12_to_fe10(z, p[2]);

    // Convert to affine coordinates
    fe10_invert(z_inverse, z);
    fe10_mul(x_affine, x, z_inverse);
    fe10_mul(y_affine, y, z_inverse);

    // Write the affine numbers to the buffer
    fe10_tobytes(&s[ 0], x_affine);
    fe10_tobytes(&s[32], y_affine);
}
