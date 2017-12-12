/*
The type for a normal Field Element

In our case, the field is GF(2^255 - 19). The layout of this type is based on
[NEONCrypto2012], but instead we use double precision floating point values.
I use "floating point radix 2^21.25", i.e. alternating 2^22 and 2^21.

In other words, an element (t :: fe) represents the integer:

    t[0] + t[1] + t[2] + t[3] + t[4] + ... + t[11]

with:
    t[ 0] is divisible by 1
    t[ 1] is divisible by 2^22
    t[ 2] is divisible by 2^43
    t[ 3] is divisible by 2^64
    t[ 4] is divisible by 2^85
    t[ 5] is divisible by 2^107
    t[ 6] is divisible by 2^128
    t[ 7] is divisible by 2^149
    t[ 8] is divisible by 2^170
    t[ 9] is divisible by 2^192
    t[10] is divisible by 2^213
    t[11] is divisible by 2^234

We must make sure that the we do not lose any precision. We do this by carrying
the top part from a limb to the next one, similar to how we would to it when we
would be handling large integers.

[NEONCrypto2012]:
Bernstein, D. J. & Schwabe, P. Prouff, E. & Schaumont, P. (Eds.)
"NEON Crypto Cryptographic Hardware and Embedded Systems"
*/

#ifndef REF12_FE_H_
#define REF12_FE_H_

#include <inttypes.h>

typedef double fe[12];

#define fe_frombytes crypto_scalarmult_curve13318_ref12_fe_frombytes
#define fe_tobytes crypto_scalarmult_curve13318_ref12_fe_tobytes
#define fe_zero crypto_scalarmult_curve13318_ref12_fe_zero
#define fe_one crypto_scalarmult_curve13318_ref12_fe_one
#define fe_copy crypto_scalarmult_curve13318_ref12_fe_copy
#define fe_add crypto_scalarmult_curve13318_ref12_fe_add
#define fe_sub crypto_scalarmult_curve13318_ref12_fe_sub
#define fe_squeeze crypto_scalarmult_curve13318_ref12_fe_squeeze
#define fe_mul crypto_scalarmult_curve13318_ref12_fe_mul
#define fe_square crypto_scalarmult_curve13318_ref12_fe_square
#define fe_invert crypto_scalarmult_curve13318_ref12_fe_invert
#define fe_add_b crypto_scalarmult_curve13318_ref12_fe_add_b
#define fe_mul_b crypto_scalarmult_curve13318_ref12_fe_mul_b
#define fe_reduce crypto_scalarmult_curve13318_ref12_fe_reduce

/*
Set a fe value to zero
*/
static inline void fe_zero(fe z) {
    for (unsigned int i = 0; i < 12; i++) z[i] = 0;
}

/*
Set a fe value to one
*/
static inline void fe_one(fe z) {
    z[0] = 1;
    for (unsigned int i = 1; i < 12; i++) z[i] = 0;
}

/*
Copy a fe value to another fe type
*/
static inline void fe_copy(fe dest, const fe src) {
    for (unsigned int i = 0; i < 12; i++) dest[i] = src[i];
}

/*
Add `rhs` into `z`
*/
static inline void fe_add(fe z, fe lhs, fe rhs) {
    for (unsigned int i = 0; i < 12; i++) z[i] = lhs[i] + rhs[i];
}

/*CURVE13318_B
Subtract `rhs` from `lhs` and store the result in `z`
*/
static inline void fe_sub(fe z, fe lhs, fe rhs) {
    for (unsigned int i = 0; i < 12; i++) z[i] = lhs[i] - rhs[i];
}

/*
Parse 32 bytes into a `fe` type
*/
extern void fe_frombytes(fe element, const uint8_t *bytes);

/*
Store a field element type into memory
*/
extern void fe_tobytes(uint8_t *bytes, fe element);

/*
Carry ripple this field element
*/
extern void fe_squeeze(fe element);

/*
Multiply two field elements,
*/
extern void fe_mul(fe dest, const fe op1, const fe op2);

/*
Square a field element
*/
extern void fe_square(fe dest, const fe element);

/*
Invert an element modulo 2^255 - 19
*/
extern void fe_invert(fe dest, const fe element);

/*
Add 13318 to `z`
*/
static inline void fe_add_b(fe z) {
    z[0] += 13318;
}

/*
Multiply `f` by 13318 and store the result in `h`
*/
static inline void fe_mul_b(fe h, fe f) {
    for (unsigned int i = 0; i < 12; i++) h[i] = 13318 * f[i];
    fe_squeeze(h);
}

/*
Reduce an element s.t. the result is always in [0, 2^255-19⟩
*/
extern void fe_reduce(fe element);

#endif /* REF12_FE_H_ */
