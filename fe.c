#include "fe.h"

void fe_squeeze(fe z)
{
    // Interleave two carry chains (8 rounds):
    //   - a: z[0] -> z[1] -> z[2] -> z[3] -> z[4]  -> z[5]  -> z[6] -> z[7]
    //   - b: z[6] -> z[7] -> z[8] -> z[9] -> z[10] -> z[11] -> z[0] -> z[1]
    //
    // Precondition:
    //   - For all limbs x in z : |x| <= 0.99 * 2^53
    //
    // Postcondition:
    //   - All significands fit in b + 1 bits (b = 22, 21, 21, etc.)

    double t0, t1;
    t0 = z[0] + 0x3p73 - 0x3p73; // Round 1a
    z[0] -= t0;
    z[1] += t0;
    t1 = z[6] + 0x3p200 - 0x3p200; // Round 1b
    z[6] -= t1;
    z[7] += t1;
    t0 = z[1] + 0x3p94 - 0x3p94; // Round 2a
    z[1] -= t0;
    z[2] += t0;
    t1 = z[7] + 0x3p221 - 0x3p221; // Round 2b
    z[7] -= t1;
    z[8] += t1;
    t0 = z[2] + 0x3p115 - 0x3p115; // Round 3a
    z[2] -= t0;
    z[3] += t0;
    t1 = z[8] + 0x3p243 - 0x3p243; // Round 3b
    z[8] -= t1;
    z[9] += t1;
    t0 = z[3] + 0x3p136 - 0x3p136; // Round 4a
    z[3] -= t0;
    z[4] += t0;
    t1 = z[9] + 0x3p264 - 0x3p264; // Round 4b
    z[9] -= t1;
    z[10] += t1;
    t0 = z[4] + 0x3p158 - 0x3p158; // Round 5a
    z[4] -= t0;
    z[5] += t0;
    t1 = z[10] + 0x3p285 - 0x3p285; // Round 5b
    z[10] -= t1;
    z[11] += t1;
    t0 = z[5] + 0x3p179 - 0x3p179; // Round 6a
    z[5] -= t0;
    z[6] += t0;
    t1 = z[11] + 0x3p306 - 0x3p306; // Round 6b
    z[11] -= t1;
    z[0] += 0x13p-255 * t1; // 19 * 2^-255
    t0 = z[6] + 0x3p200 - 0x3p200; // Round 7a
    z[6] -= t0;
    z[7] += t0;
    t1 = z[0] + 0x3p73 - 0x3p73; // Round 7b
    z[0] -= t1;
    z[1] += t1;
    t0 = z[7] + 0x3p221 - 0x3p221; // Round 8a
    z[7] -= t0;
    z[8] += t0;
    t1 = z[1] + 0x3p94 - 0x3p94; // Round 8b
    z[1] -= t1;
    z[2] += t1;
}
