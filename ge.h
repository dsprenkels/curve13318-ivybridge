/*
Group element in our curve E : y^2 = x^3 - 3*x + 13318

Because of the limitations of the Renes-Costello-Batina addition formulas, a
point on E is represented by its projective coordinates, i.e. (X : Y : Z).
*/

#ifndef CURVE13318_REF12_GE_H_
#define CURVE13318_REF12_GE_H_

#include "fe12.h"
#include "fe10.h"

typedef fe12 ge[3];

#define ge_frombytes crypto_scalarmult_curve13318_ref12_ge_frombytes
#define ge_tobytes crypto_scalarmult_curve13318_ref12_ge_tobytes
#define ge_add crypto_scalarmult_curve13318_ref12_ge_add
#define ge_double crypto_scalarmult_curve13318_ref12_ge_double

/*
Copy a ge value to another ge type
*/
static inline void ge_copy(ge dest, const ge src) {
    for (unsigned int i = 0; i < 3; i++) fe12_copy(dest[i], src[i]);
}

/*
Parse a bytestring into a point on the curve

Arguments:
  - point   Output point
  - bytes   Input bytes
Returns:
  0 on succes, nonzero on failure
*/
int ge_frombytes(ge point, const uint8_t *bytes);

/*
Convert a projective point on the curve to its byte representation

Arguments:
  - bytes   Output bytes
  - point   Output point
Returns:
  0 on succes, nonzero on failure
*/
void ge_tobytes(uint8_t *bytes, ge point);

/*
Add two `point_1` and `point_2` into `dest`.
*/
void ge_add(ge dest, const ge point_1, const ge point_2);

/*
Double `point` into `dest`.
*/
void ge_double(ge dest, const ge point);



#endif /* CURVE13318_REF12_GE_H_ */
