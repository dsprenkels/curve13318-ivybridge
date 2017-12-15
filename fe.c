#include "fe.h"
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

void fe_frombytes(fe z, const uint8_t *in)
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

void fe_mul(fe h, const fe f, const fe g)
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
    for (unsigned int i = 0; i < 12; i++) h[i] = f[0] * g[i];

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

    fe_squeeze(h);
}

void fe_square(fe h, const fe f)
{
    fe_mul(h, f, f);
}

void fe_invert(fe out, const fe z)
{
	fe z2;
	fe z9;
	fe z11;
	fe z2_5_0;
	fe z2_10_0;
	fe z2_20_0;
	fe z2_50_0;
	fe z2_100_0;
	fe t0;
	fe t1;
	unsigned int i;

	/* 2 */ fe_square(z2,z);
	/* 4 */ fe_square(t1,z2);
	/* 8 */ fe_square(t0,t1);
	/* 9 */ fe_mul(z9,t0,z);
	/* 11 */ fe_mul(z11,z9,z2);
	/* 22 */ fe_square(t0,z11);
	/* 2^5 - 2^0 = 31 */ fe_mul(z2_5_0,t0,z9);

	/* 2^6 - 2^1 */ fe_square(t0,z2_5_0);
	/* 2^7 - 2^2 */ fe_square(t1,t0);
	/* 2^8 - 2^3 */ fe_square(t0,t1);
	/* 2^9 - 2^4 */ fe_square(t1,t0);
	/* 2^10 - 2^5 */ fe_square(t0,t1);
	/* 2^10 - 2^0 */ fe_mul(z2_10_0,t0,z2_5_0);

	/* 2^11 - 2^1 */ fe_square(t0,z2_10_0);
	/* 2^12 - 2^2 */ fe_square(t1,t0);
	/* 2^20 - 2^10 */ for (i = 2;i < 10;i += 2) { fe_square(t0,t1); fe_square(t1,t0); }
	/* 2^20 - 2^0 */ fe_mul(z2_20_0,t1,z2_10_0);

	/* 2^21 - 2^1 */ fe_square(t0,z2_20_0);
	/* 2^22 - 2^2 */ fe_square(t1,t0);
	/* 2^40 - 2^20 */ for (i = 2;i < 20;i += 2) { fe_square(t0,t1); fe_square(t1,t0); }
	/* 2^40 - 2^0 */ fe_mul(t0,t1,z2_20_0);

	/* 2^41 - 2^1 */ fe_square(t1,t0);
	/* 2^42 - 2^2 */ fe_square(t0,t1);
	/* 2^50 - 2^10 */ for (i = 2;i < 10;i += 2) { fe_square(t1,t0); fe_square(t0,t1); }
	/* 2^50 - 2^0 */ fe_mul(z2_50_0,t0,z2_10_0);

	/* 2^51 - 2^1 */ fe_square(t0,z2_50_0);
	/* 2^52 - 2^2 */ fe_square(t1,t0);
	/* 2^100 - 2^50 */ for (i = 2;i < 50;i += 2) { fe_square(t0,t1); fe_square(t1,t0); }
	/* 2^100 - 2^0 */ fe_mul(z2_100_0,t1,z2_50_0);

	/* 2^101 - 2^1 */ fe_square(t1,z2_100_0);
	/* 2^102 - 2^2 */ fe_square(t0,t1);
	/* 2^200 - 2^100 */ for (i = 2;i < 100;i += 2) { fe_square(t1,t0); fe_square(t0,t1); }
	/* 2^200 - 2^0 */ fe_mul(t1,t0,z2_100_0);

	/* 2^201 - 2^1 */ fe_square(t0,t1);
	/* 2^202 - 2^2 */ fe_square(t1,t0);
	/* 2^250 - 2^50 */ for (i = 2;i < 50;i += 2) { fe_square(t0,t1); fe_square(t1,t0); }
	/* 2^250 - 2^0 */ fe_mul(t0,t1,z2_50_0);

	/* 2^251 - 2^1 */ fe_square(t1,t0);
	/* 2^252 - 2^2 */ fe_square(t0,t1);
	/* 2^253 - 2^3 */ fe_square(t1,t0);
	/* 2^254 - 2^4 */ fe_square(t0,t1);
	/* 2^255 - 2^5 */ fe_square(t1,t0);
	/* 2^255 - 21 */ fe_mul(out,t1,z11);
}
