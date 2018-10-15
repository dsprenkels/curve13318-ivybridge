; Doubling of group elements
;
; Author: Amber Sprenkels <amber@electricdusk.com>

%include "ge_double.mac"

global crypto_scalarmult_curve13318_ref12_ge_double

section .text
crypto_scalarmult_curve13318_ref12_ge_double:
    ; The next chain of procedures is an adapted version of Algorithm 6
    ; from the Renes-Costello-Batina addition laws. [Renes2016]
    ;
    ; fe12_squeeze guarantees that every processed double is always divisible
    ; by 2^k and bounded by 1.01 * 2^21 * 2^k, with k the limb's offset
    ; (0, 22, 43, etc.). This theorem (3.2) is proven in [Hash127] by Daniel
    ; Bernstein, although it needs to be adapted to this instance.
    ; Precondition of the theorem is that the input to fe12_squeeze is divisible
    ; by 2^k and bounded by 0.98 * 2^53 * 2^k.
    ;
    ; In other words: Any product limbs produced by fe12_mul (uncarried), must be
    ; bounded by ±0.98 * 2^53. In fe12_mul, the lowest limb is multiplied by the
    ; largest value, namely ±(11*19 + 1)*x*y = ±210*x*y for x the largest possible
    ; 22-bit limbs. This means that the summed limb bits of the 2 multiplied
    ; operands cannot exceed ±0.98 * 2^53 / 210. Rounded down this computes to
    ; ~±2^45.2 > ±1.1*2^45. So if we restrict ourselves to a multiplied upper bound
    ; of ±1.1*2^45, we should be all right.
    ;
    ; We would manage this by multiplying 2^21 values with 2^24 values
    ; (because 21 + 24 ≤ 45), but for example 2^23 * 2^23 is *forbidden* as it
    ; may overflow (23 + 23 > 45).
    ;
    ; TODO(dsprenkels) Vectorise 5 and 29a
    ;
    %push ge_double_ctx
    %xdefine stack_size 6*384 + 192 + 768

    ; build stack frame
    push rbp
    mov rbp, rsp
    and rsp, -32
    sub rsp, stack_size
    ge_double rdi, rsi, rsp
    mov rsp, rbp
    pop rbp
    ret

section .rodata
fe12x4_mul_consts
fe12x4_squeeze_consts
ge_double_consts
