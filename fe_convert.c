#include "fe_convert.h"

void convert_fe12_to_fe10(fe10 out, const fe12 z)
{
    uint64_t z0 = (uint64_t)  (z[ 0] + z[ 1]);
    uint64_t z1 = (uint64_t) ((z[ 2] + z[ 3]) * 0x1p-43);
    uint64_t z2 = (uint64_t) ((z[ 4] + z[ 5]) * 0x1p-85);
    uint64_t z3 = (uint64_t) ((z[ 6] + z[ 7]) * 0x1p-128);
    uint64_t z4 = (uint64_t) ((z[ 8] + z[ 9]) * 0x1p-170);
    uint64_t z5 = (uint64_t) ((z[10] + z[11]) * 0x1p-213);

    // Because of fe12_squeeze, we know that the limbs are bounded by
    // [2^44 - 1, 2^43 - 1, 2^44 - 1, 2^43 - 1, 2^44 - 1, 2^43 - 1].
    // At this point, limbs in z may still be < 0, so we add a large multiple
    // of p (in this case 8*p) to guarantee that all limbs will be positive.
    z0 += 0x1FFFFFFFFF68;
    z1 += 0x0FFFFFFFFFFC;
    z2 += 0x1FFFFFFFFFFC;
    z3 += 0x0FFFFFFFFFFC;
    z4 += 0x1FFFFFFFFFFC;
    z5 += 0x1FFFFFFFFFFC;

    // We currently have only 6 limbs, this would be a good opportunity to do
    // a carry ripple.
    uint64_t t0, t1;
    t0 = z0 & _MASK43; // Round 1a
    z0 ^= t0;
    z1 += t0 >> 43;
    t1 = z3 & _MASK42; // Round 1b
    z3 ^= t1;
    z4 += t1 >> 42;
    t0 = z1 & _MASK42; // Round 2a
    z1 ^= t0;
    z2 += t0 >> 42;
    t1 = z4 & _MASK43; // Round 2b
    z4 ^= t1;
    z5 += t1 >> 43;
    t0 = z2 & _MASK43; // Round 3a
    z2 ^= t0;
    z3 += t0 >> 43;
    t1 = z5 & _MASK42; // Round 3b
    z5 ^= t1;
    z0 += 19 * (t1 >> 42);
    // We are done at this point, because the repacking below fixes the rest.
    // Round 4a: z0 keeps  8 bits empty in out[1]
    // Round 4b: z3 keeps  9 bits empty in out[6]
    // Round 5a: z1 keeps 17 bits empty in out[3]
    // Round 5b: z4 keeps 17 bits empty in out[8]

    out[0]  = (z0 & 0x3FFFFFF);
    out[1]  = (z0 >> 26);
    out[1] += (z1 & 0x00000FF) << 17;
    out[2]  = (z1 >>  8) & 0x3FFFFFF;
    out[3]  = (z1 >> 34);
    out[3] += (z2 & 0x001FFFF) << 8;
    out[4]  = (z2 >> 17);
    out[5]  = (z3 & 0x1FFFFFF);
    out[6]  = (z3 >> 25);
    out[6] += (z4 & 0x00001FF) << 17;
    out[7]  = (z4 >>  9) & 0x1FFFFFF;
    out[8]  = (z4 >> 34);
    out[8] += (z5 & 0x001FFFF) << 9;
    out[9]  = (z5 >> 17);
}
