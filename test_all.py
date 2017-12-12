#!/bin/echo Please execute with sage -python
# *-* encoding: utf-8 *-*

import ctypes
import io
import os
import sys
import unittest

from sage.all import *

P = 2**255 - 19

from hypothesis import example, given, strategies as st

# Load shared libcurve13318 library
ref12 = ctypes.CDLL(os.path.join(os.path.abspath('.'), 'libref12.so'))

# Define functions
# fe_frombytes = ref12.crypto_scalarmult_curve13318_ref12_fe_frombytes
# fe_frombytes.argtypes = [ctypes.c_double * 12, ctypes.c_ubyte * 32]
# fe_tobytes = ref12.crypto_scalarmult_curve13318_ref12_fe_tobytes
# fe_tobytes.argtypes = [ctypes.c_ubyte * 32, ctypes.c_double * 12]
fe_squeeze = ref12.crypto_scalarmult_curve13318_ref12_fe_squeeze
fe_squeeze.argtypes = [ctypes.c_double * 12]
fe_mul = ref12.crypto_scalarmult_curve13318_ref12_fe_mul
fe_mul.argtypes = [ctypes.c_double * 12] * 3
fe_square = ref12.crypto_scalarmult_curve13318_ref12_fe_square
fe_square.argtypes = [ctypes.c_double * 12] * 2
fe_invert = ref12.crypto_scalarmult_curve13318_ref12_fe_invert
fe_invert.argtypes = [ctypes.c_double * 12] * 2
# fe_reduce = ref12.crypto_scalarmult_curve13318_ref12_fe_reduce
# fe_reduce.argtypes = [ctypes.c_double * 12]

def fe_val(z):
    return sum(int(x) for x in z)

class TestFE(unittest.TestCase):
    st_unsqueezed = st.lists(
        st.integers(-0.99 * 2**53, 0.99 * 2**53), min_size=12, max_size=12)
    st_squeezed_0 = st.tuples(
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
    st_squeezed_1 = st.tuples(
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

    def setUp(self):
        self.F = FiniteField(P)

    def make_fe(self, limbs=[]):
        """Encode the number in its C representation"""
        z = self.F(0)
        z_c = (ctypes.c_double * 12)(0.0)
        shift = 0
        for i, limb in enumerate(limbs):
            limb_val = 2**shift * limb
            z += self.F(limb_val)
            z_c[i] = float(limb_val)
            shift += 22 if i % 4 == 0 else 21
        return z, z_c

    @given(st_unsqueezed)
    def test_squeeze(self, limbs):
        expected, z_c = self.make_fe(limbs)
        fe_squeeze(z_c)

        # Are all limbs reduced?
        shift = 0
        for i, limb in enumerate(z_c):
            # Check theorem 2.4
            assert int(limb) % 2**shift == 0, (i, hex(int(limb)), shift)
            shift += 22 if i % 4 == 0 else 21
            assert abs(int(limb)) <= 2**(shift-1), (i, hex(int(limb)), shift)
        # Decode the value
        actual = sum(self.F(int(x)) for x in z_c)
        self.assertEqual(actual, expected)

    @given(st_squeezed_0, st_squeezed_1, st.booleans())
    def test_mul(self, f_limbs, g_limbs, swap):
        if swap:
            f_limbs, g_limbs = g_limbs, f_limbs
        f, f_c = self.make_fe(f_limbs)
        g, g_c = self.make_fe(g_limbs)
        _, h_c = self.make_fe()
        expected = f * g
        fe_mul(h_c, f_c, g_c)
        actual = sum(self.F(int(x)) for x in h_c)
        self.assertEqual(actual, expected)

    @given(st_squeezed_0)
    def test_square(self, f_limbs):
        f, f_c = self.make_fe(f_limbs)
        _, h_c = self.make_fe()
        expected = f**2
        fe_square(h_c, f_c)
        actual = sum(self.F(int(x)) for x in h_c)
        self.assertEqual(actual, expected)

    @given(st_squeezed_0)
    def test_invert(self, f_limbs):
        f, f_c = self.make_fe(f_limbs)
        _, h_c = self.make_fe()
        expected = f**-1 if f != 0 else 0
        fe_invert(h_c, f_c)
        actual = sum(self.F(int(x)) for x in h_c)
        self.assertEqual(actual, expected)


if __name__ == '__main__':
    unittest.main()
