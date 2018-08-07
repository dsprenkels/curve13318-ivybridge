#include <stdint.h>

typedef double fe12[12];

static inline double unset_bit59(const double x)
{
    union {
        double f64;
        uint64_t u64;
    } tmp = { .f64 = x };
    tmp.u64 &= 0xF7FFFFFFFFFFFFFF;
    return tmp.f64;
}

void fe12_mul_2_ref(fe12 C, const fe12 A, const fe12 B)
{
    double l0, l1, l2, l3, l4, l5, l6, l7, l8, l9, l10;
    double h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10;

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

    // Precompute reduced A,B values
    // For x7-x10, we know for sure that they are:
    //   - either 0 -> exponent of double is 0b00000000000
    //   - 0 modulo 2^149 and smaller than 2^237 and as such, the 7'th exponent bit is always set.
    //     Thus we can use a mask operation for these values to divide them by 2*128.
    const double  A6_shr = 0x1p-128 * A[ 6];
    const double  A7_shr = unset_bit59(A[7]);
    const double  A8_shr = unset_bit59(A[8]);
    const double  A9_shr = unset_bit59(A[9]);
    const double A10_shr = unset_bit59(A[10]);
    const double A11_shr = 0x1p-128 * A[11];
    const double  B6_shr = 0x1p-128 * B[ 6];
    const double  B7_shr = unset_bit59(B[7]);
    const double  B8_shr = unset_bit59(B[8]);
    const double  B9_shr = unset_bit59(B[9]);
    const double B10_shr = unset_bit59(B[10]);
    const double B11_shr = 0x1p-128 * B[11];

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

    C[ 0] = h0;
    C[ 1] = h1;
    C[ 2] = h2;
    C[ 3] = h3;
    C[ 4] = h4;
    C[ 5] = h5;
    C[ 6] = h6;
    C[ 7] = h7;
    C[ 8] = h8;
    C[ 9] = h9;
    C[10] = h10;
}
