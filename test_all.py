#!/bin/echo Please execute with sage -python
# *-* encoding: utf-8 *-*

import ctypes
import io
import os
import sys
import unittest

from sage.all import *

P = 2**255 - 19
F = FiniteField(P)
E = EllipticCurve(F, [-3, 13318])

from hypothesis import assume, example, given, note, strategies as st

# Load shared libcurve13318 library
ref12 = ctypes.CDLL(os.path.join(os.path.abspath('.'), 'libref12.so'))

# Define C types
fe12_type = ctypes.c_double * 12
fe12_frozen_type = ctypes.c_double * 6
fe10_type = ctypes.c_uint64 * 10
fe10_frozen_type = ctypes.c_uint64 * 5
ge_type = fe12_type * 3

# Define functions
fe12_frombytes = ref12.crypto_scalarmult_curve13318_ref12_fe12_frombytes
fe12_frombytes.argtypes = [fe12_type, ctypes.c_ubyte * 32]
fe12_squeeze = ref12.crypto_scalarmult_curve13318_ref12_fe12_squeeze
fe12_squeeze.argtypes = [fe12_type]
fe12_mul = ref12.crypto_scalarmult_curve13318_ref12_fe12_mul
fe12_mul.argtypes = [fe12_type, fe12_type, fe12_type]
fe12_square = ref12.crypto_scalarmult_curve13318_ref12_fe12_square
fe12_square.argtypes = [fe12_type, fe12_type]
fe10_tobytes = ref12.crypto_scalarmult_curve13318_ref12_fe10_tobytes
fe10_tobytes.argtypes = [ctypes.c_ubyte * 32, fe10_type]
fe10_mul = ref12.crypto_scalarmult_curve13318_ref12_fe10_mul
fe10_mul.argtypes = [fe10_type, fe10_type, fe10_type]
fe10_carry = ref12.crypto_scalarmult_curve13318_ref12_fe10_carry
fe10_carry.argtypes = [fe10_type]
fe10_square = ref12.crypto_scalarmult_curve13318_ref12_fe10_square
fe10_square.argtypes = [fe10_type, fe10_type]
fe10_invert = ref12.crypto_scalarmult_curve13318_ref12_fe10_invert
fe10_invert.argtypes = [fe10_type, fe10_type]
fe10_reduce = ref12.crypto_scalarmult_curve13318_ref12_fe10_reduce
fe10_reduce.argtypes = [fe10_frozen_type, fe10_type]
convert_fe12_to_fe10 = ref12.crypto_scalarmult_curve13318_ref12_convert_fe12_to_fe10
convert_fe12_to_fe10.argtypes = [fe10_type, fe12_type]
ge_frombytes = ref12.crypto_scalarmult_curve13318_ref12_ge_frombytes
ge_frombytes.argtypes = [ge_type, ctypes.c_ubyte * 64]
# ge_tobytes = ref12.crypto_scalarmult_curve13318_ref12_ge_tobytes
# ge_tobytes.argtypes = [ctypes.c_ubyte * 64, ctypes.c_uint64 * 30]
# ge_add = ref12.crypto_scalarmult_curve13318_ref12_ge_add
# ge_add.argtypes = [ctypes.c_uint64 * 30] * 3


# Custom testing strategies

st_fe12_unsqueezed = st.lists(
    st.integers(-0.99 * 2**53, 0.99 * 2**53), min_size=12, max_size=12)
st_fe12_squeezed_0 = st.tuples(
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**21, 1.01 * 2**21),
    st.integers(-1.01 * 2**21, 1.01 * 2**21),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**21, 1.01 * 2**21),
    st.integers(-1.01 * 2**21, 1.01 * 2**21),
    st.integers(-1.01 * 2**21, 1.01 * 2**21),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**21, 1.01 * 2**21),
    st.integers(-1.01 * 2**21, 1.01 * 2**21),
    st.integers(-1.01 * 2**21, 1.01 * 2**21))
st_fe12_squeezed_1 = st.tuples(
    st.integers(-1.01 * 2**23, 1.01 * 2**23),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**23, 1.01 * 2**23),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**23, 1.01 * 2**23),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**22, 1.01 * 2**22))
st_fe10_carried_0 = st.lists(st.integers(0, 2**26), min_size=10, max_size=10)
st_fe10_carried_1 = st.lists(st.integers(0, 2**27), min_size=10, max_size=10)
st_fe10_carried_2 = st.lists(st.integers(0, 2**28), min_size=10, max_size=10)
st_fe10_uncarried = st.lists(st.integers(0, 2**63), min_size=10, max_size=10)


class TestFE12(unittest.TestCase):
    @given(st.lists(st.integers(0, 255), min_size=32, max_size=32))
    def test_frombytes(self, s):
        expected = sum(F(x) * 2**(8*i) for i,x in enumerate(s))
        s_c = (ctypes.c_ubyte * 32)(*s)
        _, z_c = make_fe12()
        fe12_frombytes(z_c, s_c)
        actual = sum(F(int(x)) for x in z_c)
        self.assertEqual(actual, expected)

    @given(st_fe12_unsqueezed)
    def test_squeeze(self, limbs):
        expected, z_c = make_fe12(limbs)
        fe12_squeeze(z_c)

        # Are all limbs reduced?
        exponent = 0
        for i, limb in enumerate(z_c):
            # Check theorem 2.4
            assert int(limb) % 2**exponent == 0, (i, hex(int(limb)), exponent)
            exponent += 22 if i % 4 == 0 else 21
            assert abs(int(limb)) <= 2**(exponent-1), (i, hex(int(limb)), exponent)
        # Decode the value
        actual = sum(F(int(x)) for x in z_c)
        self.assertEqual(actual, expected)

    @given(st_fe12_squeezed_0, st_fe12_squeezed_1, st.booleans())
    def test_mul(self, f_limbs, g_limbs, swap):
        if swap:
            f_limbs, g_limbs = g_limbs, f_limbs
        f, f_c = make_fe12(f_limbs)
        g, g_c = make_fe12(g_limbs)
        _, h_c = make_fe12()
        expected = f * g
        fe12_mul(h_c, f_c, g_c)
        actual = F(fe12_val(h_c))
        self.assertEqual(actual, expected)

    @given(st_fe12_squeezed_0)
    def test_square(self, f_limbs):
        f, f_c = make_fe12(f_limbs)
        _, h_c = make_fe12()
        expected = f**2
        fe12_square(h_c, f_c)
        actual = F(fe12_val(h_c))
        self.assertEqual(actual, expected)


class TestFE10(unittest.TestCase):
    @given(st_fe10_carried_0)
    def test_tobytes(self, limbs):
        expected, z_c = make_fe10(limbs)
        c_bytes = (ctypes.c_ubyte * 32)(0)
        fe10_tobytes(c_bytes, z_c)
        actual = sum(x * 2**(8*i) for i,x in enumerate(c_bytes))
        self.assertEqual(actual, expected)

    @given(st_fe10_carried_2, st_fe10_carried_2)
    def test_mul(self, f_limbs, g_limbs):
        f, f_c = make_fe10(f_limbs)
        g, g_c = make_fe10(g_limbs)
        _, h_c = make_fe10()
        expected = f * g
        fe10_mul(h_c, f_c, g_c)
        actual = 0
        exponent = 0
        actual = fe10_val(h_c)
        self.assertEqual(actual, expected)

    @given(st_fe10_carried_2)
    def test_square(self, limbs):
        f, f_c = make_fe10(limbs)
        expected = F(f**2)
        _, h_c = make_fe10()
        fe10_square(h_c, f_c)
        actual = F(fe10_val(h_c))
        self.assertEqual(actual, expected)

    @given(st_fe10_uncarried)
    def test_carry(self, limbs):
        expected, z_c = make_fe10(limbs)
        fe10_carry(z_c)
        actual = fe10_val(z_c)
        assert(actual < 2**256)
        self.assertEqual(F(actual), expected)
        for limb in z_c:
            assert(0 <= limb <= 2**26)

    @given(st_fe10_carried_2)
    def test_invert(self, limbs):
        f, f_c = make_fe10(limbs)
        expected = F(f)**-1 if f != 0 else 0
        _, h_c = make_fe10()
        fe10_invert(h_c, f_c)
        actual = F(fe10_val(h_c))
        self.assertEqual(actual, expected)

    @given(st_fe10_carried_0)
    # Value that that is in [p, 2^255⟩
    @example([2**26 -19, 2**25, 2**26, 2**25, 2**26,
              2**25,     2**26, 2**25, 2**26, 2**25 ])
    def test_reduce(self, limbs):
        z, z_c = make_fe10(limbs)
        z_frozen = fe10_frozen_type(0)
        expected = F(z)
        fe10_reduce(z_frozen, z_c)
        actual = sum(x * 2**(51*i) for i,x in enumerate(z_frozen))
        self.assertEqual(actual, expected)
        assert(0 <= actual < 2**255 - 19)


class TestConvert(unittest.TestCase):
    @given(st_fe12_squeezed_0)
    def test_convert_fe12_to_fe10(self, limbs):
        expected, z12_c = make_fe12(limbs)
        _, z10_c = make_fe10()
        convert_fe12_to_fe10(z10_c, z12_c)
        actual = F(fe10_val(z10_c))
        self.assertEqual(actual, expected)
        for limb in z10_c:
            assert(0 <= limb <= 2**26)

class TestGE(unittest.TestCase):
    def encode_point(x, y, z):
        """Encode a point in its C representation"""
        shift = 0
        x_limbs, y_limbs, z_limbs = [0]*10, [0]*10, [0]*10
        for i in range(10):
            mask_width = 26 if i % 2 == 0 else 25
            x_limbs[i] = (2**mask_width - 1) & (x.lift() >> shift)
            y_limbs[i] = (2**mask_width - 1) & (y.lift() >> shift)
            z_limbs[i] = (2**mask_width - 1) & (z.lift() >> shift)
            shift += mask_width

        p = (ctypes.c_uint64 * 30)(0)
        for i, limb in enumerate(x_limbs + y_limbs + z_limbs):
            p[i] = limb
        return p

    @staticmethod
    def decode_point(point):
        x = fe12_val(point[0])
        y = fe12_val(point[1])
        z = fe12_val(point[2])
        return (x, y, z)

    @staticmethod
    def decode_bytes(c_bytes):
        x, y = F(0), F(0)
        for i, b in enumerate(c_bytes[0:32]):
            x += b * 2**(8*i)
        for i, b in enumerate(c_bytes[32:64]):
            y += b * 2**(8*i)
        return x, y

    @staticmethod
    def point_to_bytes(x, y):
        """Encode the numbers as byte input"""
        # Encode the numbers as byte input
        c_bytes = (ctypes.c_ubyte * 64)(0)
        for i in range(32):
            c_bytes[i] = (x >> (8*i)) & 0xFF
        for i in range(32):
            c_bytes[32+i] = (y >> (8*i)) & 0xFF
        return c_bytes

    @given(st.integers(0, 2**256 - 1), st.integers(0, 2**256 - 1),
           st.sampled_from([1, -1]))
    @example(0, 0, 1) # point at infinity
    @example(0, P, 1)
    @example(0, 2*P, 1)
    def test_frombytes(self, x, y_suggest, sign):
        x = F(x)
        try:
            x, y = (sign * E(x, y_suggest)).xy()
            y_in = y
            expected = 0
        except TypeError:
            # `sqrt` failed
            if F(x) == 0 and F(y_suggest) == 0:
                # Point at infinity
                y_in, y = F(0), F(1)
                z = F(0)
                expected = 0
            else:
                # Invalid input
                y = F(y_suggest)
                y_in = y
                z = F(1)
                expected = -1

        c_bytes = self.point_to_bytes(x.lift(), y_in.lift())
        c_point = ge_type(fe12_type(0))
        ret = ge_frombytes(c_point, c_bytes)
        actual_x, actual_y, actual_z = self.decode_point(c_point)
        self.assertEqual(ret, expected)
        if ret != 0: return
        self.assertEqual(actual_x, x)
        self.assertEqual(actual_y, y)
        self.assertEqual(actual_z, z)

    @given(st.integers(0, 2**256 - 1), st.integers(0, 2**256 - 1),
           st.sampled_from([1, -1]),   st.integers(0, 2**256 - 1),
           st.integers(0, 2**256 - 1), st.sampled_from([1, -1]))
    @example(0, 0, 1, 0, 0, 1)
    def test_add_ref(self, x1, z1, sign1, x2, z2, sign2):
        (x1, y1, z1), point1 = make_ge(x1, z1, sign1)
        (x2, y2, z2), point2 = make_ge(x2, z2, sign2)
        note("testing: {} + {}".format(point1, point2))
        note("locals(): {}".format(locals()))
        x1, y1, z1 = F(x1), F(y1), F(z1)
        x2, y2, z2 = F(x2), F(y2), F(z2)
        b = 13318
        t0 = x1 * x2;        t1 = y1 * y2;        t2 = z1 * z2
        t3 = x1 + y1;        t4 = x2 + y2;        t3 = t3 * t4
        t4 = t0 + t1;        t3 = t3 - t4;        t4 = y1 + z1
        x3 = y2 + z2;        t4 = t4 * x3;        x3 = t1 + t2
        t4 = t4 - x3;        x3 = x1 + z1;        y3 = x2 + z2
        x3 = x3 * y3;        y3 = t0 + t2;        y3 = x3 - y3
        z3 =  b * t2;        x3 = y3 - z3;        z3 = x3 + x3
        x3 = x3 + z3;        z3 = t1 - x3;        x3 = t1 + x3
        y3 =  b * y3;        t1 = t2 + t2;        t2 = t1 + t2
        y3 = y3 - t2;        y3 = y3 - t0;        t1 = y3 + y3
        y3 = t1 + y3;        t1 = t0 + t0;        t0 = t1 + t0
        t0 = t0 - t2;        t1 = t4 * y3;        t2 = t0 * y3
        y3 = x3 * z3;        y3 = y3 + t2;        x3 = x3 * t3
        x3 = x3 - t1;        z3 = z3 * t4;        t1 = t3 * t0
        z3 = z3 + t1
        self.assertEqual(E([x3, y3, z3]), point1 + point2)


def make_fe12(limbs=[]):
    """Encode the number in its C representation"""
    z = F(0)
    z_c = (ctypes.c_double * 12)(0.0)
    exponent = 0
    for i, limb in enumerate(limbs):
        limb_val = 2**exponent * limb
        z += F(limb_val)
        z_c[i] = float(limb_val)
        exponent += 22 if i % 4 == 0 else 21
    return z, z_c

def fe12_val(z):
    return sum(int(x) for x in z)

def make_fe10(initial_value=[]):
    z = F(0)
    z_c = (ctypes.c_uint64 * 10)(0)
    exponent = 0
    for i, limb in enumerate(initial_value):
        z += limb * 2**exponent
        z_c[i] = limb
        exponent += 26 if i % 2 == 0 else 25
    return z, z_c

def fe10_val(h):
    val = 0
    exponent = 0
    for i, limb in enumerate(h):
        val += limb * 2**exponent
        exponent += 26 if i % 2 == 0 else 25
    return val

def make_ge(x, z, sign):
    if z != 0:
        try:
            point = sign * E.lift_x(F(x))
        except ValueError:
            assume(False)
        x, y = point.xy()
        z = F(z)
        x, y = z * x, z * y
    else:
        point = E(0)
        x, y, z = F(0), F(1), F(z)
    return (x, y, z), point


if __name__ == '__main__':
    unittest.main()
