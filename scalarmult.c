/*
    This code follows the SUPERCOP crypto_scalarmult convention.

    It implements exception free scalar multiplication over the curve
    `E : y^2 = x^3 - 3*x + 13318`.
*/

#include "ge.h"
#include <stdbool.h>
#include <stdint.h>

#define scalarmult crypto_scalarmult_curve13318_scalarmult

static void cmov(ge dest, const ge src, bool c)
{
    for (unsigned int i = 0; i < 3; i++) {
        for (unsigned int j = 0; j < 12; j++) {
            dest[i][j] = (!c)*dest[i][j] + c*src[i][j];
        }
    }
}

static void select(ge dest, uint8_t idx, const ge ptable[16])
{
    for (unsigned int i = 0; i < 16; i++) cmov(dest, ptable[i], i == idx);
}

static void ladderstep(ge q, ge ptable[17], uint8_t bits)
{
    ge p;
    // Our lookup table is one-based indexed. The neutral element is not stored
    // in `ptable`, but written by `ge_zero`. The mapping from `bits` to `idx`
    // is defined by the following:
    //
    // compute_idx :: Word8 -> Word8
    // compute_idx bits
    //   |  0 <= bits < 16 = x - 1  // sign is (+)
    //   | 16 <= bits < 32 = ~x     // sign is (-)
    const uint8_t sign = (bits >> 4) & 0x01;
    const uint8_t signmask = -(int8_t)sign;
    const uint8_t idx = ((~bits & signmask) | ((bits - 1) & ~signmask)) & 0x1F;

    for (int i = 0; i < 5; i++) ge_double(q, q);
    ge_zero(p);
    select(p, idx, ptable);
    ge_cneg(p, sign);
    ge_add(q, q, p);

}

static void ladder(const uint8_t *e, ge q, const ge p)
{
    ge ptable[16];
    uint8_t w[51], zeroth_window;

    // Do precomputation
    ge_copy(ptable[0], p);
    ge_double(ptable[1], ptable[0]);
    ge_add(ptable[2], ptable[1], ptable[0]);
    ge_double(ptable[3], ptable[1]);
    ge_add(ptable[4], ptable[3], ptable[0]);
    ge_double(ptable[5], ptable[2]);
    ge_add(ptable[6], ptable[5], ptable[0]);
    ge_double(ptable[7], ptable[3]);
    ge_add(ptable[8], ptable[7], ptable[0]);
    ge_double(ptable[9], ptable[4]);
    ge_add(ptable[10], ptable[9], ptable[0]);
    ge_double(ptable[11], ptable[5]);
    ge_add(ptable[12], ptable[11], ptable[0]);
    ge_double(ptable[13], ptable[6]);
    ge_add(ptable[14], ptable[13], ptable[0]);
    ge_double(ptable[15], ptable[7]);

    // Decode the key bytes into windows
    // TODO(dsprenkels) Reverse the order of parsing and immediately ripple
    w[ 0] = (e[31] >> 2) & 0x1F;
    w[ 1] = ((e[31] << 3) | (e[30] >> 5)) & 0x1F;
    w[ 2] = e[30] & 0x1F;
    w[ 3] = (e[29] >> 3) & 0x1F;
    w[ 4] = ((e[29] << 2) | (e[28] >> 6)) & 0x1F;
    w[ 5] = (e[28] >> 1) & 0x1F;
    w[ 6] = ((e[28] << 4) | (e[27] >> 4)) & 0x1F;
    w[ 7] = ((e[27] << 1) | (e[26] >> 7)) & 0x1F;
    w[ 8] = (e[26] >> 2) & 0x1F;
    w[ 9] = ((e[26] << 3) | (e[25] >> 5)) & 0x1F;
    w[10] = e[25] & 0x1F;
    w[11] = (e[24] >> 3) & 0x1F;
    w[12] = ((e[24] << 2) | (e[23] >> 6)) & 0x1F;
    w[13] = (e[23] >> 1) & 0x1F;
    w[14] = ((e[23] << 4) | (e[22] >> 4)) & 0x1F;
    w[15] = ((e[22] << 1) | (e[21] >> 7)) & 0x1F;
    w[16] = (e[21] >> 2) & 0x1F;
    w[17] = ((e[21] << 3) | (e[20] >> 5)) & 0x1F;
    w[18] = e[20] & 0x1F;
    w[19] = (e[19] >> 3) & 0x1F;
    w[20] = ((e[19] << 2) | (e[18] >> 6)) & 0x1F;
    w[21] = (e[18] >> 1) & 0x1F;
    w[22] = ((e[18] << 4) | (e[17] >> 4)) & 0x1F;
    w[23] = ((e[17] << 1) | (e[16] >> 7)) & 0x1F;
    w[24] = (e[16] >> 2) & 0x1F;
    w[25] = ((e[16] << 3) | (e[15] >> 5)) & 0x1F;
    w[26] = e[15] & 0x1F;
    w[27] = (e[14] >> 3) & 0x1F;
    w[28] = ((e[14] << 2) | (e[13] >> 6)) & 0x1F;
    w[29] = (e[13] >> 1) & 0x1F;
    w[30] = ((e[13] << 4) | (e[12] >> 4)) & 0x1F;
    w[31] = ((e[12] << 1) | (e[11] >> 7)) & 0x1F;
    w[32] = (e[11] >> 2) & 0x1F;
    w[33] = ((e[11] << 3) | (e[10] >> 5)) & 0x1F;
    w[34] = e[10] & 0x1F;
    w[35] = (e[ 9] >> 3) & 0x1F;
    w[36] = ((e[ 9] << 2) | (e[ 8] >> 6)) & 0x1F;
    w[37] = (e[ 8] >> 1) & 0x1F;
    w[38] = ((e[ 8] << 4) | (e[ 7] >> 4)) & 0x1F;
    w[39] = ((e[ 7] << 1) | (e[ 6] >> 7)) & 0x1F;
    w[40] = (e[ 6] >> 2) & 0x1F;
    w[41] = ((e[ 6] << 3) | (e[ 5] >> 5)) & 0x1F;
    w[42] = e[ 5] & 0x1F;
    w[43] = (e[ 4] >> 3) & 0x1F;
    w[44] = ((e[ 4] << 2) | (e[ 3] >> 6)) & 0x1F;
    w[45] = (e[ 3] >> 1) & 0x1F;
    w[46] = ((e[ 3] << 4) | (e[ 2] >> 4)) & 0x1F;
    w[47] = ((e[ 2] << 1) | (e[ 1] >> 7)) & 0x1F;
    w[48] = (e[ 1] >> 2) & 0x1F;
    w[49] = ((e[ 1] << 3) | (e[ 0] >> 5)) & 0x1F;
    w[50] = e[ 0] & 0x1F;

    // Ripple through the signed windows and add if previous window is negative
    for (unsigned int i = 50; i >= 1; i--) {
        w[i-1] += ((w[i] >> 5) ^ (w[i] >> 4)) & 0x1;
    }
    zeroth_window = ((w[0] >> 5) ^ (w[0] >> 4)) & 0x1;

    // Do double and add scalar multiplication
    ge_zero(q);
    cmov(q, ptable[0], zeroth_window & 0x01);
    cmov(q, ptable[1], zeroth_window >> 1);
    for (unsigned int i = 0; i < 51; i++) {
        ladderstep(q, ptable, w[i]);
    }
}

int scalarmult(uint8_t *out, const uint8_t *key, const uint8_t *in)
{
    ge p, q;
    uint8_t e[32];

    for (unsigned int i = 0; i < 32; i++) e[i] = key[i];
    e[31] &= 127; // We do not use the 255'th bit from the key


    int err = ge_frombytes(p, in);
    if (err != 0) {
        return -1;
    }
    ladder(e, q, p);
    ge_tobytes(out, q);
    return 0;
}
