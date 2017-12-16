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

from hypothesis import example, given, strategies as st

# Load shared libcurve13318 library
ref12 = ctypes.CDLL(os.path.join(os.path.abspath('.'), 'libref12.so'))

# Define C types
fe12_type = ctypes.c_double * 12
fe12_frozen_type = ctypes.c_double * 6
fe10_type = ctypes.c_uint64 * 10
fe10_frozen_type = ctypes.c_uint64 * 5

# Define functions
fe12_frombytes = ref12.crypto_scalarmult_curve13318_ref12_fe12_frombytes
fe12_frombytes.argtypes = [fe12_type, ctypes.c_ubyte * 32]
fe12_squeeze = ref12.crypto_scalarmult_curve13318_ref12_fe12_squeeze
fe12_squeeze.argtypes = [fe12_type]
fe12_mul = ref12.crypto_scalarmult_curve13318_ref12_fe12_mul
fe12_mul.argtypes = [fe12_type, fe12_type, fe12_type]
fe12_square = ref12.crypto_scalarmult_curve13318_ref12_fe12_square
fe12_square.argtypes = [fe12_type, fe12_type]
fe12_invert = ref12.crypto_scalarmult_curve13318_ref12_fe12_invert
fe12_invert.argtypes = [fe12_type, fe12_type]
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

    @given(st_fe12_squeezed_0)
    def test_invert(self, f_limbs):
        f, f_c = make_fe12(f_limbs)
        _, h_c = make_fe12()
        expected = f**-1 if f != 0 else 0
        fe12_invert(h_c, f_c)
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


if __name__ == '__main__':
    unittest.main()
