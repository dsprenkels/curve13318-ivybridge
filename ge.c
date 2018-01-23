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
    fe10_square(lhs, p1);    // y^2
    fe10_square(t0, p0);     // x^2
    fe10_mul(rhs, t0, p0);   // x^3
    fe10_zero(t0);           // 0
    fe10_add2p(t0);          // 0
    fe10_sub(t0, t0, p0);    // -x
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

void ge_add(ge p3, const ge p1, const ge p2)
{
    fe12 x1, y1, z1, x2, y2, z2, x3, y3, z3, t0, t1, t2, t3, t4, t5;
    fe12_copy(x1, p1[0]);
    fe12_copy(y1, p1[1]);
    fe12_copy(z1, p1[2]);
    fe12_copy(x2, p2[0]);
    fe12_copy(y2, p2[1]);
    fe12_copy(z2, p2[2]);

    /*
    The next chain of procedures is *exactly* Algorithm 4 from the
    Renes-Costello-Batina addition laws. [Renes2016]

    fe12_squeeze guarantees that every processed double is always divisible
    by 2^k and bounded by 1.01 * 2^21 * 2^k, with k the limb's offset
    (0, 22, 43, etc.). This theorem (3.2) is proven in [Hash127] by Daniel
    Bernstein, although it needs to be adapted to this instance.
    Precondition of the theorem is that the input to fe12_squeeze is divisible
    by 2^k and bounded by 0.98 * 2^53 * 2^k.

    In other words: Any product limbs produced by fe12_mul (uncarried), must be
    bounded by ±0.98 * 2^53. In fe12_mul, the lowest limb is multiplied by the
    largest value, namely ±(11*19 + 1)*x*y = ±210*x*y for x the largest possible
    22-bit limbs. This means that the summed limb bits of the 2 multiplied
    operands cannot exceed ±0.98 * 2^53 / 210. Rounded down this computes to
    ~±2^45.2. So if we restrict ourselves to a multiplied upper bound of
    ±1.01*2^45, we should be all right.

    We would manage this by multiplying 2^21 values with 2^24 values
    (because 21 + 24 ≤ 45), but for example 2^23 * 2^23 is *forbidden* as it
    may overflow (23 + 23 > 45).
    */
    /*   #: Instruction number as mentioned in the paper */
             // Assume forall x in {x1, z1, x2, z2} : |x| ≤ 1.01 * 2^21
             //        forall x in {y1, y2} :         |x| ≤ 1.01 * 2^22
             fe12_mul(t0, x1, x2); // |t0| ≤ 1.01 * 2^21
             fe12_mul(t1, y1, y2); // |t1| ≤ 1.01 * 2^21
             fe12_mul(t2, z1, z2); // |t2| ≤ 1.01 * 2^21
             fe12_add(t3, x1, y1); // |t3| ≤ 1.01 * (2^22 + 2^21)
    /*  5 */ fe12_add(t4, x2, y2); // |t4| ≤ 1.01 * (2^22 + 2^21)
             fe12_copy(t5, t3); fe12_mul(t3, t5, t4); // |t3| ≤ 1.01 * 2^21
             fe12_add(t4, t0, t1); // |t4| ≤ 1.01 * 2^22
             fe12_sub(t3, t3, t4); // |t3| ≤ 1.01 * (2^22 + 2^21)
             fe12_add(t4, y1, z1); // |t4| ≤ 1.01 * (2^22 + 2^21)
    /* 10 */ fe12_add(x3, y2, z2); // |x3| ≤ 1.01 * (2^22 + 2^21)
             fe12_copy(t5, t4); fe12_mul(t4, t5, x3); // |t4| ≤ 1.01 * 2^21
             fe12_add(x3, t1, t2); // |x3| ≤ 1.01 * 2^22
             fe12_sub(t4, t4, x3); // |t4| ≤ 1.01 * (2^22 + 2^21)
             fe12_add(x3, x1, z1); // |x3| ≤ 1.01 * 2^22
    /* 15 */ fe12_add(y3, x2, z2); // |y3| ≤ 1.01 * 2^22
             fe12_copy(t5, x3); fe12_mul(x3, t5, y3); // |x3| ≤ 1.01 * 2^21
             fe12_add(y3, t0, t2); // |y3| ≤ 1.01 * 2^22
             fe12_sub(y3, x3, y3); // |y3| ≤ 1.01 * (2^22 + 2^21)
             fe12_mul_b(z3, t2);   // |z3| ≤ 1.01 * 2^21
    /* 20 */ fe12_sub(x3, y3, z3); // |x3| ≤ 1.01 * 2^23
             fe12_add(z3, x3, x3); // |z3| ≤ 1.01 * 2^24
             fe12_add(x3, x3, z3); // |x3| ≤ 1.01 * (2^24 + 2^23)
             fe12_copy(t5, t1); fe12_sub(z3, t5, x3); // |z3| ≤ 1.01 * (2^24 + 2^23 + 2^21)
             fe12_add(x3, t1, x3); // |x3| ≤ 1.01 * (2^24 + 2^23 + 2^21)
    /* 25 */ fe12_mul_b(y3, y3);   // |y3| ≤ 1.01 * 2^21
             fe12_add(t1, t2, t2); // |t1| ≤ 1.01 * 2^22
             fe12_add(t2, t1, t2); // |t2| ≤ 1.01 * (2^22 + 2^21)
             fe12_sub(y3, y3, t2); // |y3| ≤ 1.01 * 2^23
             fe12_sub(y3, y3, t0); // |y3| ≤ 1.01 * (2^23 + 2^21)
    /* 30 */ fe12_add(t1, y3, y3); // |t1| ≤ 1.01 * (2^24 + 2^22)
             fe12_add(y3, t1, y3); // |y3| ≤ 1.01 * (2^24 + 2^23 + 2^22 + 2^21)
             fe12_add(t1, t0, t0); // |t1| ≤ 1.01 * 2^22
             fe12_add(t0, t1, t0); // |t0| ≤ 1.01 * (2^22 + 2^21)
             fe12_sub(t0, t0, t2); // |t0| ≤ 1.01 * (2^23 + 2^22)
    /* __ */ fe12_squeeze(x3);     // extra squeeze |x3| ≤ 1.01 * 2^21
    /* __ */ fe12_squeeze(t0);     // extra squeeze |z3| ≤ 1.01 * 2^21
    /* __ */ fe12_squeeze(z3);     // extra squeeze |z3| ≤ 1.01 * 2^21
    /* __ */ fe12_squeeze(y3);     // extra squeeze |y3| ≤ 1.01 * 2^21
    /* 35 */ fe12_mul(t1, t4, y3); // |t1| ≤ 1.01 * 2^21
             fe12_mul(t2, t0, y3); // |t2| ≤ 1.01 * 2^21
             fe12_mul(y3, x3, z3); // |y3| ≤ 1.01 * 2^21
             fe12_add(y3, y3, t2); // |y3| ≤ 1.01 * 2^22
             fe12_copy(t5, x3); fe12_mul(x3, t5, t3); // |x3| ≤ 1.01 * 2^21
    /* 40 */ fe12_sub(x3, x3, t1); // |x3| ≤ 1.01 * 2^22
             fe12_copy(t5, z3); fe12_mul(z3, t5, t4); // |z3| ≤ 1.01 * 2^21
             fe12_mul(t1, t3, t0); // |t1| ≤ 1.01 * 2^21
             fe12_add(z3, z3, t1); // |z3| ≤ 1.01 * 2^22

    // Squeeze x3 and z3, otherwise we will get into trouble during the next
    // Addition/doubling
    fe12_squeeze(x3);
    fe12_squeeze(z3);

    fe12_copy(p3[0], x3);
    fe12_copy(p3[1], y3);
    fe12_copy(p3[2], z3);
}
