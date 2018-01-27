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

static void ladder(const uint8_t *k, ge q, const ge p)
{
    ge tmp;
    ge_zero(q);
    for (int i = 31; i >= 0; i--) {
        for (int j = 7; j >= 0; j--) {
            bool bit = (k[i] >> j) & 1;
            ge_double(q, q);
            ge_add(tmp, q, p);
            cmov(q, tmp, bit);
        }
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
