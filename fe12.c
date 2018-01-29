#include "fe12.h"
#include <inttypes.h>

static inline uint32_t load_3(const uint8_t *in)
{
  uint32_t ret;
  ret = (uint32_t) in[0];
  ret |= ((uint32_t) in[1]) << 8;
  ret |= ((uint32_t) in[2]) << 16;
  return ret;
}

static inline uint32_t load_2(const uint8_t *in)
{
  uint32_t ret;
  ret = (uint32_t) in[0];
  ret |= ((uint32_t) in[1]) << 8;
  return ret;
}

void fe12_frombytes(fe12 z, const uint8_t *in)
{
    uint32_t z0  = load_3(in);
    uint32_t z1  = load_3(in +  3) << 2;
    uint32_t z2  = load_2(in +  6) << 5;
    uint32_t z3  = load_3(in +  8);
    uint32_t z4  = load_3(in + 11) << 3;
    uint32_t z5  = load_2(in + 14) << 5;
    uint32_t z6  = load_3(in + 16);
    uint32_t z7  = load_3(in + 19) << 3;
    uint32_t z8  = load_2(in + 22) << 6;
    uint32_t z9  = load_3(in + 24);
    uint32_t z10 = load_3(in + 27) << 3;
    uint32_t z11 = load_2(in + 30) << 6;

    uint32_t carry11 = z11 >> 21;  z0 += 19 * carry11; z11 &= 0x1FFFFF;
    uint32_t  carry1 =  z1 >> 21;  z2 += carry1; z1 &= 0x1FFFFF;
    uint32_t  carry3 =  z3 >> 21;  z4 += carry3; z3 &= 0x1FFFFF;
    uint32_t  carry5 =  z5 >> 21;  z6 += carry5; z5 &= 0x1FFFFF;
    uint32_t  carry7 =  z7 >> 21;  z8 += carry7; z7 &= 0x1FFFFF;
    uint32_t  carry9 =  z9 >> 21; z10 += carry9; z9 &= 0x1FFFFF;

    uint32_t  carry0 =  z0 >> 22;  z1 += carry0; z0 &= 0x3FFFFF;
    uint32_t  carry2 =  z2 >> 21;  z2 += carry2; z2 &= 0x1FFFFF;
    uint32_t  carry4 =  z4 >> 22;  z5 += carry4; z4 &= 0x3FFFFF;
    uint32_t  carry6 =  z6 >> 21;  z7 += carry6; z6 &= 0x1FFFFF;
    uint32_t  carry8 =  z8 >> 22;  z9 += carry8; z8 &= 0x3FFFFF;
    uint32_t carry10 = z10 >> 21; z11 += carry10; z10 &= 0x1FFFFF;

    z[0] =  (double)z0;
    z[1] =  (double)z1 * 0x1p22;
    z[2] =  (double)z2 * 0x1p43;
    z[3] =  (double)z3 * 0x1p64;
    z[4] =  (double)z4 * 0x1p85;
    z[5] =  (double)z5 * 0x1p107;
    z[6] =  (double)z6 * 0x1p128;
    z[7] =  (double)z7 * 0x1p149;
    z[8] =  (double)z8 * 0x1p170;
    z[9] =  (double)z9 * 0x1p192;
    z[10] = (double)z10 * 0x1p213;
    z[11] = (double)z11 * 0x1p234;
}

void fe12_squeeze(fe12 z)
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

void fe12_mul(fe12 C, const fe12 A, const fe12 B)
{
    double l0, l1, l2, l3, l4, l5, l6, l7, l8, l9, l10;
    double h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10;
    double m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10;

    // Precompute reduced A,B values
    const double  A6_shr = 0x1p-128 * A[ 6];
    const double  A7_shr = 0x1p-128 * A[ 7];
    const double  A8_shr = 0x1p-128 * A[ 8];
    const double  A9_shr = 0x1p-128 * A[ 9];
    const double A10_shr = 0x1p-128 * A[10];
    const double A11_shr = 0x1p-128 * A[11];
    const double  B6_shr = 0x1p-128 * B[ 6];
    const double  B7_shr = 0x1p-128 * B[ 7];
    const double  B8_shr = 0x1p-128 * B[ 8];
    const double  B9_shr = 0x1p-128 * B[ 9];
    const double B10_shr = 0x1p-128 * B[10];
    const double B11_shr = 0x1p-128 * B[11];

    // Compute L
    l0  = A[0] * B[0]; // Round 1/6
    l1  = A[0] * B[1];
    l2  = A[0] * B[2];
    l3  = A[0] * B[3];
    l4  = A[0] * B[4];
    l5  = A[0] * B[5];
    l1 += A[1] * B[0]; // Round 2/6
    l2 += A[1] * B[1];
    l3 += A[1] * B[2];
    l4 += A[1] * B[3];
    l5 += A[1] * B[4];
    l6  = A[1] * B[5];
    l2 += A[2] * B[0]; // Round 3/6
    l3 += A[2] * B[1];
    l4 += A[2] * B[2];
    l5 += A[2] * B[3];
    l6 += A[2] * B[4];
    l7  = A[2] * B[5];
    l3 += A[3] * B[0]; // Round 4/6
    l4 += A[3] * B[1];
    l5 += A[3] * B[2];
    l6 += A[3] * B[3];
    l7 += A[3] * B[4];
    l8  = A[3] * B[5];
    l4 += A[4] * B[0]; // Round 5/6
    l5 += A[4] * B[1];
    l6 += A[4] * B[2];
    l7 += A[4] * B[3];
    l8 += A[4] * B[4];
    l9  = A[4] * B[5];
    l5 += A[5] * B[0]; // Round 6/6
    l6 += A[5] * B[1];
    l7 += A[5] * B[2];
    l8 += A[5] * B[3];
    l9 += A[5] * B[4];
    l10 = A[5] * B[5];

    // Compute H
    h0  =  A6_shr *  B6_shr; // Round 1/6
    h1  =  A6_shr *  B7_shr;
    h2  =  A6_shr *  B8_shr;
    h3  =  A6_shr *  B9_shr;
    h4  =  A6_shr * B10_shr;
    h5  =  A6_shr * B11_shr;
    h1 +=  A7_shr *  B6_shr; // Round 2/6
    h2 +=  A7_shr *  B7_shr;
    h3 +=  A7_shr *  B8_shr;
    h4 +=  A7_shr *  B9_shr;
    h5 +=  A7_shr * B10_shr;
    h6  =  A7_shr * B11_shr;
    h2 +=  A8_shr *  B6_shr; // Round 3/6
    h3 +=  A8_shr *  B7_shr;
    h4 +=  A8_shr *  B8_shr;
    h5 +=  A8_shr *  B9_shr;
    h6 +=  A8_shr * B10_shr;
    h7  =  A8_shr * B11_shr;
    h3 +=  A9_shr *  B6_shr; // Round 4/6
    h4 +=  A9_shr *  B7_shr;
    h5 +=  A9_shr *  B8_shr;
    h6 +=  A9_shr *  B9_shr;
    h7 +=  A9_shr * B10_shr;
    h8  =  A9_shr * B11_shr;
    h4 += A10_shr *  B6_shr; // Round 5/6
    h5 += A10_shr *  B7_shr;
    h6 += A10_shr *  B8_shr;
    h7 += A10_shr *  B9_shr;
    h8 += A10_shr * B10_shr;
    h9  = A10_shr * B11_shr;
    h5 += A11_shr *  B6_shr; // Round 6/6
    h6 += A11_shr *  B7_shr;
    h7 += A11_shr *  B8_shr;
    h8 += A11_shr *  B9_shr;
    h9 += A11_shr * B10_shr;
    h10 = A11_shr * B11_shr;

    // Compute M_hat
    const double mA0 = (A[0] -  A6_shr);
    const double mA1 = (A[1] -  A7_shr);
    const double mA2 = (A[2] -  A8_shr);
    const double mA3 = (A[3] -  A9_shr);
    const double mA4 = (A[4] - A10_shr);
    const double mA5 = (A[5] - A11_shr);
    const double mB0 = (B[0] -  B6_shr);
    const double mB1 = (B[1] -  B7_shr);
    const double mB2 = (B[2] -  B8_shr);
    const double mB3 = (B[3] -  B9_shr);
    const double mB4 = (B[4] - B10_shr);
    const double mB5 = (B[5] - B11_shr);
    m0  = mA0 * mB0; // Round 1/6
    m1  = mA0 * mB1;
    m2  = mA0 * mB2;
    m3  = mA0 * mB3;
    m4  = mA0 * mB4;
    m5  = mA0 * mB5;
    m1 += mA1 * mB0; // Round 2/6
    m2 += mA1 * mB1;
    m3 += mA1 * mB2;
    m4 += mA1 * mB3;
    m5 += mA1 * mB4;
    m6  = mA1 * mB5;
    m2 += mA2 * mB0; // Round 3/6
    m3 += mA2 * mB1;
    m4 += mA2 * mB2;
    m5 += mA2 * mB3;
    m6 += mA2 * mB4;
    m7  = mA2 * mB5;
    m3 += mA3 * mB0; // Round 4/6
    m4 += mA3 * mB1;
    m5 += mA3 * mB2;
    m6 += mA3 * mB3;
    m7 += mA3 * mB4;
    m8  = mA3 * mB5;
    m4 += mA4 * mB0; // Round 5/6
    m5 += mA4 * mB1;
    m6 += mA4 * mB2;
    m7 += mA4 * mB3;
    m8 += mA4 * mB4;
    m9  = mA4 * mB5;
    m5 += mA5 * mB0; // Round 6/6
    m6 += mA5 * mB1;
    m7 += mA5 * mB2;
    m8 += mA5 * mB3;
    m9 += mA5 * mB4;
    m10 = mA5 * mB5;

    // Sum up the accs into C
    C[ 0] =  l0 + 0x26p-128 * ( -m6 +  l6 +  h6) + 0x26*h0;
    C[ 1] =  l1 + 0x26p-128 * ( -m7 +  l7 +  h7) + 0x26*h1;
    C[ 2] =  l2 + 0x26p-128 * ( -m8 +  l8 +  h8) + 0x26*h2;
    C[ 3] =  l3 + 0x26p-128 * ( -m9 +  l9 +  h9) + 0x26*h3;
    C[ 4] =  l4 + 0x26p-128 * (-m10 + l10 + h10) + 0x26*h4;
    C[ 5] =  l5                                  + 0x26*h5;
    C[ 6] =  l6 +  0x1p+128 * ( -m0 +  l0 +  h0) + 0x26*h6;
    C[ 7] =  l7 +  0x1p+128 * ( -m1 +  l1 +  h1) + 0x26*h7;
    C[ 8] =  l8 +  0x1p+128 * ( -m2 +  l2 +  h2) + 0x26*h8;
    C[ 9] =  l9 +  0x1p+128 * ( -m3 +  l3 +  h3) + 0x26*h9;
    C[10] = l10 +  0x1p+128 * ( -m4 +  l4 +  h4) + 0x26*h10;
    C[11] =        0x1p+128 * ( -m5 +  l5 +  h5);
    fe12_squeeze(C);
}

void fe12_mul_schoolbook(fe12 h, const fe12 f, const fe12 g)
{
    // Precompute reduced g values
    const double  g1_19 = 0x13p-255 * g[ 1];
    const double  g2_19 = 0x13p-255 * g[ 2];
    const double  g3_19 = 0x13p-255 * g[ 3];
    const double  g4_19 = 0x13p-255 * g[ 4];
    const double  g5_19 = 0x13p-255 * g[ 5];
    const double  g6_19 = 0x13p-255 * g[ 6];
    const double  g7_19 = 0x13p-255 * g[ 7];
    const double  g8_19 = 0x13p-255 * g[ 8];
    const double  g9_19 = 0x13p-255 * g[ 9];
    const double g10_19 = 0x13p-255 * g[10];
    const double g11_19 = 0x13p-255 * g[11];

    // Round  1/12
    h[ 0] = f[0] * g[ 0];
    h[ 1] = f[0] * g[ 1];
    h[ 2] = f[0] * g[ 2];
    h[ 3] = f[0] * g[ 3];
    h[ 4] = f[0] * g[ 4];
    h[ 5] = f[0] * g[ 5];
    h[ 6] = f[0] * g[ 6];
    h[ 7] = f[0] * g[ 7];
    h[ 8] = f[0] * g[ 8];
    h[ 9] = f[0] * g[ 9];
    h[10] = f[0] * g[10];
    h[11] = f[0] * g[11];

    // Round  2/12
    h[ 0] += f[ 1] * g11_19;
    h[ 1] += f[ 1] * g[ 0];
    h[ 2] += f[ 1] * g[ 1];
    h[ 3] += f[ 1] * g[ 2];
    h[ 4] += f[ 1] * g[ 3];
    h[ 5] += f[ 1] * g[ 4];
    h[ 6] += f[ 1] * g[ 5];
    h[ 7] += f[ 1] * g[ 6];
    h[ 8] += f[ 1] * g[ 7];
    h[ 9] += f[ 1] * g[ 8];
    h[10] += f[ 1] * g[ 9];
    h[11] += f[ 1] * g[10];

    // Round  3/12
    h[ 0] += f[ 2] * g10_19;
    h[ 1] += f[ 2] * g11_19;
    h[ 2] += f[ 2] * g[ 0];
    h[ 3] += f[ 2] * g[ 1];
    h[ 4] += f[ 2] * g[ 2];
    h[ 5] += f[ 2] * g[ 3];
    h[ 6] += f[ 2] * g[ 4];
    h[ 7] += f[ 2] * g[ 5];
    h[ 8] += f[ 2] * g[ 6];
    h[ 9] += f[ 2] * g[ 7];
    h[10] += f[ 2] * g[ 8];
    h[11] += f[ 2] * g[ 9];

    // Round  4/12
    h[ 0] += f[ 3] * g9_19;
    h[ 1] += f[ 3] * g10_19;
    h[ 2] += f[ 3] * g11_19;
    h[ 3] += f[ 3] * g[ 0];
    h[ 4] += f[ 3] * g[ 1];
    h[ 5] += f[ 3] * g[ 2];
    h[ 6] += f[ 3] * g[ 3];
    h[ 7] += f[ 3] * g[ 4];
    h[ 8] += f[ 3] * g[ 5];
    h[ 9] += f[ 3] * g[ 6];
    h[10] += f[ 3] * g[ 7];
    h[11] += f[ 3] * g[ 8];

    // Round  5/12
    h[ 0] += f[ 4] * g8_19;
    h[ 1] += f[ 4] * g9_19;
    h[ 2] += f[ 4] * g10_19;
    h[ 3] += f[ 4] * g11_19;
    h[ 4] += f[ 4] * g[ 0];
    h[ 5] += f[ 4] * g[ 1];
    h[ 6] += f[ 4] * g[ 2];
    h[ 7] += f[ 4] * g[ 3];
    h[ 8] += f[ 4] * g[ 4];
    h[ 9] += f[ 4] * g[ 5];
    h[10] += f[ 4] * g[ 6];
    h[11] += f[ 4] * g[ 7];

    // Round  6/12
    h[ 0] += f[ 5] * g7_19;
    h[ 1] += f[ 5] * g8_19;
    h[ 2] += f[ 5] * g9_19;
    h[ 3] += f[ 5] * g10_19;
    h[ 4] += f[ 5] * g11_19;
    h[ 5] += f[ 5] * g[ 0];
    h[ 6] += f[ 5] * g[ 1];
    h[ 7] += f[ 5] * g[ 2];
    h[ 8] += f[ 5] * g[ 3];
    h[ 9] += f[ 5] * g[ 4];
    h[10] += f[ 5] * g[ 5];
    h[11] += f[ 5] * g[ 6];

    // Round  7/12
    h[ 0] += f[ 6] * g6_19;
    h[ 1] += f[ 6] * g7_19;
    h[ 2] += f[ 6] * g8_19;
    h[ 3] += f[ 6] * g9_19;
    h[ 4] += f[ 6] * g10_19;
    h[ 5] += f[ 6] * g11_19;
    h[ 6] += f[ 6] * g[ 0];
    h[ 7] += f[ 6] * g[ 1];
    h[ 8] += f[ 6] * g[ 2];
    h[ 9] += f[ 6] * g[ 3];
    h[10] += f[ 6] * g[ 4];
    h[11] += f[ 6] * g[ 5];

    // Round  8/12
    h[ 0] += f[ 7] * g5_19;
    h[ 1] += f[ 7] * g6_19;
    h[ 2] += f[ 7] * g7_19;
    h[ 3] += f[ 7] * g8_19;
    h[ 4] += f[ 7] * g9_19;
    h[ 5] += f[ 7] * g10_19;
    h[ 6] += f[ 7] * g11_19;
    h[ 7] += f[ 7] * g[ 0];
    h[ 8] += f[ 7] * g[ 1];
    h[ 9] += f[ 7] * g[ 2];
    h[10] += f[ 7] * g[ 3];
    h[11] += f[ 7] * g[ 4];

    // Round  9/12
    h[ 0] += f[ 8] * g4_19;
    h[ 1] += f[ 8] * g5_19;
    h[ 2] += f[ 8] * g6_19;
    h[ 3] += f[ 8] * g7_19;
    h[ 4] += f[ 8] * g8_19;
    h[ 5] += f[ 8] * g9_19;
    h[ 6] += f[ 8] * g10_19;
    h[ 7] += f[ 8] * g11_19;
    h[ 8] += f[ 8] * g[ 0];
    h[ 9] += f[ 8] * g[ 1];
    h[10] += f[ 8] * g[ 2];
    h[11] += f[ 8] * g[ 3];

    // Round 10/12
    h[ 0] += f[ 9] * g3_19;
    h[ 1] += f[ 9] * g4_19;
    h[ 2] += f[ 9] * g5_19;
    h[ 3] += f[ 9] * g6_19;
    h[ 4] += f[ 9] * g7_19;
    h[ 5] += f[ 9] * g8_19;
    h[ 6] += f[ 9] * g9_19;
    h[ 7] += f[ 9] * g10_19;
    h[ 8] += f[ 9] * g11_19;
    h[ 9] += f[ 9] * g[ 0];
    h[10] += f[ 9] * g[ 1];
    h[11] += f[ 9] * g[ 2];

    // Round 11/12
    h[ 0] += f[10] * g2_19;
    h[ 1] += f[10] * g3_19;
    h[ 2] += f[10] * g4_19;
    h[ 3] += f[10] * g5_19;
    h[ 4] += f[10] * g6_19;
    h[ 5] += f[10] * g7_19;
    h[ 6] += f[10] * g8_19;
    h[ 7] += f[10] * g9_19;
    h[ 8] += f[10] * g10_19;
    h[ 9] += f[10] * g11_19;
    h[10] += f[10] * g[ 0];
    h[11] += f[10] * g[ 1];

    // Round 12/12
    h[ 0] += f[11] * g1_19;
    h[ 1] += f[11] * g2_19;
    h[ 2] += f[11] * g3_19;
    h[ 3] += f[11] * g4_19;
    h[ 4] += f[11] * g5_19;
    h[ 5] += f[11] * g6_19;
    h[ 6] += f[11] * g7_19;
    h[ 7] += f[11] * g8_19;
    h[ 8] += f[11] * g9_19;
    h[ 9] += f[11] * g10_19;
    h[10] += f[11] * g11_19;
    h[11] += f[11] * g[ 0];

    fe12_squeeze(h);
}

void fe12_square(fe12 h, const fe12 f)
{
    fe12_mul(h, f, f);
}
