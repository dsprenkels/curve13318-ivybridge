#!/bin/echo Please execute with sage -python
# *-* encoding: utf-8 *-*

import ctypes
import io
import os
import unittest

from sage.all import *

P = 2**255 - 19
F = FiniteField(P)
E = EllipticCurve(F, [-3, 13318])

from hypothesis import assume, example, given, note, seed, settings, strategies as st, unlimited

settings.register_profile("ci", settings(deadline=None,
                                         max_examples=10000,
                                         timeout=unlimited))

if os.environ.get('CI', None) == '1':
    settings.load_profile("ci")

# Load shared libcurve13318 library
reftests = ctypes.CDLL(os.path.join(os.path.abspath('.'), 'libreftests.so'))

# Define C types
fe12_type = ctypes.c_double * 12
fe12x4_type = ctypes.c_double * 48

# Define functionsl10
fe12_mul_1 = reftests.fe12_mul_1
fe12_mul_1.argtypes = [fe12x4_type, fe12x4_type, fe12x4_type]
fe12_mul_1_ref = reftests.fe12_mul_1_ref
fe12_mul_1_ref.argtypes = [fe12_type, fe12_type, fe12_type]
fe12_mul_2 = reftests.fe12_mul_2
fe12_mul_2.argtypes = [fe12x4_type, fe12x4_type, fe12x4_type]
fe12_mul_2_ref = reftests.fe12_mul_2_ref
fe12_mul_2_ref.argtypes = [fe12_type, fe12_type, fe12_type]

# Custom testing strategies

st_fe12_unsqueezed = st.lists(
    st.integers(-0.99 * 2**53, 0.99 * 2**53), min_size=12, max_size=12)
st_fe12_squeezed_0 = st.tuples(
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**21, 1.01 * 2**21),
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
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**23, 1.01 * 2**23),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**23, 1.01 * 2**23),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**22, 1.01 * 2**22),
    st.integers(-1.01 * 2**22, 1.01 * 2**22))


class TestFE12x4(unittest.TestCase):
    @staticmethod
    def do_test_mul(test_mul_fn, ref_mul_fn):
        def do_test_mul_inner(self, f_limbs, g_limbs, lane, swap):
            fhex = lambda x: [x.hex() for x in list(x)]
            if swap:
                f_limbs, g_limbs = g_limbs, f_limbs
            _, f = make_fe12(f_limbs)
            _, g = make_fe12(g_limbs)
            _, h = make_fe12()
            ref_mul_fn(h, f, g)
            note("  f: {}".format(fhex(f)))
            note("  g: {}".format(fhex(g)))
            note("  h: {}".format(fhex(h)))
            _, fx4 = make_fe12x4(f_limbs, lane)
            _, gx4 = make_fe12x4(g_limbs, lane)
            _, hx4 = make_fe12x4([], lane)
            test_mul_fn(hx4, fx4, gx4)
            note("fx4: {}".format(fhex(list(fx4)[lane::4])))
            note("gx4: {}".format(fhex(list(gx4)[lane::4])))
            note("hx4: {}".format(fhex(list(hx4)[lane::4])))
            self.assertEqual(fe12x4_val(hx4, lane), fe12_val(h))
        return do_test_mul_inner

    @given(st_fe12_squeezed_0, st_fe12_squeezed_1, st.integers(0, 3), st.booleans())
    def test_mul_1(self, f_limbs, g_limbs, lane, swap):
        self.do_test_mul(fe12_mul_1, fe12_mul_1_ref)(self, f_limbs, g_limbs, lane, swap)

    @given(st_fe12_squeezed_0, st_fe12_squeezed_1, st.integers(0, 3), st.booleans())
    def test_mul_2(self, f_limbs, g_limbs, lane, swap):
        self.do_test_mul(fe12_mul_2, fe12_mul_2_ref)(self, f_limbs, g_limbs, lane, swap)


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

def make_fe12x4(limbs, lane):
    assert 0 <= lane < 4
    z, z_c = make_fe12(limbs)
    stashed = []
    vz_c = (ctypes.c_double * 48)(0.0)
    while ctypes.addressof(vz_c) % 32 != 0:
        # Try until we have a properly aligned array
        stashed.append(vz_c) # save the old one or else Python is going to be smart on us
        vz_c = (ctypes.c_double * 48)(0.0)
    for i, limb in enumerate(z_c):
        vz_c[4*i + lane] = limb
    return z, vz_c

def fe12_val(z):
    return sum(int(x) for x in z)

def fe12x4_val(z, lane):
    return sum(int(x) for x in z[lane::4])


if __name__ == '__main__':
    unittest.main()
