; Multiplication function for field elements (integers modulo 2^255 - 19)
;
; Author: Amber Sprenkels <amber@electricdusk.com>

%include "bench.asm"

section .rodata:

_bench1_name: db `fe12_mul_gcc\0`
_bench2_name: db `fe12_mul_clang\0`
_bench3_name: db `fe12_mul_asm\0`
_bench4_name: db `fe12_mul_asm_v2\0`
_bench5_name: db `fe12_mul_sandy2x\0`

align 8, db 0
_bench_fns_arr:
dq fe12_mul_gcc, fe12_mul_clang, fe12_mul_asm, fe12_mul_asm_v2, fe12_mul_sandy2x

_bench_names_arr:
dq _bench1_name, _bench2_name, _bench3_name, _bench4_name, _bench5_name

_bench_fns: dq _bench_fns_arr
_bench_names: dq _bench_names_arr
_bench_fns_n: dd 5

section .bss
align 32
scratch_space: resb 1536

%macro  fe12x4_mul_body_1 4
    ; Multiply two field elements using subtractive karatsuba method: body
    ;
    ; Arguments:
    ;   - %0:       address to the product of A and B
    ;   - %1:       two vectorized field element operand A
    ;   - %2:       two vectorized field element operand B
    ;   - %3:       address to 768 (24*32) aligned bytes of scratch space

    %push fe12x4_mul_body_1_ctx
    %xdefine C          %1
    %xdefine A          %2
    %xdefine B          %3
    %xdefine l          %4
    %xdefine A6_shr     %4 + 32*11
    %xdefine h          %4 + 32*12
    %xdefine A11_shr    %4 + 32*23

    ; compute L
    ; ymm9 will stores intermediate values, ymm10..ymm15 will stores the accumulators
    ; round 1/6
    vmulpd ymm10, ymm6, ymm0        ; l0 := A[0] * B[0]
    vmovapd yword [l], ymm10        ; store l[0]
    vmulpd ymm11, ymm6, ymm1        ; l1 := A[0] * B[1]
    vmulpd ymm12, ymm6, ymm2        ; l2 := A[0] * B[2]
    vmulpd ymm13, ymm6, ymm3        ; l3 := A[0] * B[3]
    vmovapd ymm4, yword [B+128]     ; load B[4]
    vmulpd ymm14, ymm6, ymm4        ; l4 := A[0] * B[4]
    vmovapd ymm5, yword [B+160]     ; load B[5]
    vmulpd ymm15, ymm6, ymm5        ; l5 := A[0] * B[5]
    ; round 2/6
    vmulpd ymm9, ymm7, ymm0
    vaddpd ymm11, ymm11, ymm9       ; l1 += A[1] * B[0]
    vmovapd yword [l+32], ymm11     ; store l1
    vmulpd ymm9, ymm7, ymm1
    vaddpd ymm12, ymm12, ymm9       ; l2 += A[1] * B[1]
    vmulpd ymm9, ymm7, ymm2
    vaddpd ymm13, ymm13, ymm9       ; l3 += A[1] * B[2]
    vmulpd ymm9, ymm7, ymm3
    vaddpd ymm14, ymm14, ymm9       ; l4 += A[1] * B[3]
    vmulpd ymm9, ymm7, ymm4
    vaddpd ymm15, ymm15, ymm9       ; l5 += A[1] * B[4]
    vmulpd ymm10, ymm7, ymm5        ; l6 := A[1] * B[5]
    ; round 3/6
    vmovapd ymm8, yword [A+64]      ; load A[2]
    vmulpd ymm9, ymm8, ymm0
    vaddpd ymm12, ymm12, ymm9       ; l2 += A[2] * B[0]
    vmovapd yword [l+64], ymm12     ; store l2
    vmulpd ymm9, ymm8, ymm1
    vaddpd ymm13, ymm13, ymm9       ; l3 += A[2] * B[1]
    vmulpd ymm9, ymm8, ymm2
    vaddpd ymm14, ymm14, ymm9       ; l4 += A[2] * B[2]
    vmulpd ymm9, ymm8, ymm3
    vaddpd ymm15, ymm15, ymm9       ; l5 += A[2] * B[3]
    vmulpd ymm9, ymm8, ymm4
    vaddpd ymm10, ymm10, ymm9       ; l6 += A[2] * B[4]
    vmulpd ymm11, ymm8, ymm5        ; l7 := A[2] * B[5]
    ; round 4/6
    vmovapd ymm6, yword [A+96]      ; load A[3]
    vmulpd ymm9, ymm6, ymm0
    vaddpd ymm13, ymm13, ymm9       ; l3 += A[3] * B[0]
    vmovapd yword [l+96], ymm13     ; store l3
    vmulpd ymm9, ymm6, ymm1
    vaddpd ymm14, ymm14, ymm9       ; l4 += A[3] * B[1]
    vmulpd ymm9, ymm6, ymm2
    vaddpd ymm15, ymm15, ymm9       ; l5 += A[3] * B[2]
    vmulpd ymm9, ymm6, ymm3
    vaddpd ymm10, ymm10, ymm9       ; l6 += A[3] * B[3]
    vmulpd ymm9, ymm6, ymm4
    vaddpd ymm11, ymm11, ymm9       ; l7 += A[3] * B[4]
    vmulpd ymm12, ymm6, ymm5        ; l8 := A[3] * B[5]
    ; round 5/6
    vmovapd ymm7, yword [A+128]     ; load A[4]
    vmulpd ymm9, ymm7, ymm0
    vaddpd ymm14, ymm14, ymm9       ; l4 += A[4] * B[0]
    vmovapd yword [l+128], ymm14    ; store l4
    vmulpd ymm9, ymm7, ymm1
    vaddpd ymm15, ymm15, ymm9       ; l5 += A[4] * B[1]
    vmulpd ymm9, ymm7, ymm2
    vaddpd ymm10, ymm10, ymm9       ; l6 += A[4] * B[2]
    vmulpd ymm9, ymm7, ymm3
    vaddpd ymm11, ymm11, ymm9       ; l7 += A[4] * B[3]
    vmulpd ymm9, ymm7, ymm4
    vaddpd ymm12, ymm12, ymm9       ; l8 += A[4] * B[4]
    vmulpd ymm13, ymm7, ymm5        ; l9 := A[4] * B[5]
    ; round 6/6
    vmovapd ymm8, yword [A+160]     ; load A[5]
    vmulpd ymm9, ymm8, ymm0
    vaddpd ymm15, ymm15, ymm9       ; l5 += A[5] * B[0]
    vmovapd yword [l+160], ymm15    ; store l5
    vmulpd ymm9, ymm8, ymm1
    vaddpd ymm10, ymm10, ymm9       ; l6 += A[5] * B[1]
    vmovapd yword [l+192], ymm10    ; store l6
    vmulpd ymm9, ymm8, ymm2
    vaddpd ymm11, ymm11, ymm9       ; l7 += A[5] * B[2]
    vmovapd yword [l+224], ymm11    ; store l7
    vmulpd ymm9, ymm8, ymm3
    vaddpd ymm12, ymm12, ymm9       ; l8 += A[5] * B[3]
    vmovapd yword [l+256], ymm12    ; store l8
    vmulpd ymm9, ymm8, ymm4
    vaddpd ymm13, ymm13, ymm9       ; l9 += A[5] * B[4]
    vmovapd yword [l+288], ymm13    ; store l9
    vmulpd ymm14, ymm8, ymm5        ; l10:= A[5] * B[5]
    vmovapd yword [l+320], ymm14    ; store l10

    ; compute H
    ; We will:
    ;   - precompute the A6_shr,A11_shr,Bx_shr values and,
    ;   - compute the A7_shr..A10_shr values on the fly, because they can be done in parallel
    ;     with vmulpd instruction.
    ;
    ; In this part of the code I will apply a really specific optimisation: For {A,B}x7-{A,B}x10,
    ; we know for sure that they are:
    ;   - either 0, and so exponent part of the double is '0b00000000000'
    ;   - 0 modulo 2^149 and smaller than 2^237 => as such, the 7'th exponent bit is always set.
    ;     Thus we can use a mask operation for these values to divide them by 2*128.
    ;
    vmovapd ymm8, yword [rel .const_1_1p_neg128]
    vmovapd ymm9, yword [rel .const_unset_bit59_mask]
    vmulpd ymm6, ymm8, yword [A+192]   ;  A6_shr = 0x1p-128 * A[ 6];
    vmulpd ymm0, ymm8, yword [B+192]   ;  B6_shr = 0x1p-128 * B[ 6];
    vandpd ymm1, ymm9, yword [B+224]   ;  B7_shr = unset_bit59(B[7]);
    vandpd ymm2, ymm9, yword [B+256]   ;  B8_shr = unset_bit59(B[8]);
    vandpd ymm3, ymm9, yword [B+288]   ;  B9_shr = unset_bit59(B[9]);
    vandpd ymm4, ymm9, yword [B+320]   ; B10_shr = unset_bit59(B[10]);
    vmulpd ymm5, ymm8, yword [B+352]   ; B11_shr = 0x1p-128 * B[11];
    vmulpd ymm7, ymm8, yword [A+352]   ; A11_shr = 0x1p-128 * A[11];

    ; TODO(dsprenkels) Currently I am deliberately forgetting A{7..10}_shr, because storing and
    ; loading will probably take the same resources as loading and vandpd'ing. Check if this is
    ; actually true.
    ; TODO(dsprenkels) We don't actually need to spill A6_shr, I think. Every round we rotate by
    ; one register. I.e. in round 2, the register ymm10 is only used in the end, so we can safely
    ; use ymm10 for temporary values during that round. Now we have an extra register in which we
    ; can retain A6_shr (or some other useful values).

    ; Just as in the computation of L, we will store the accumulators (h) in ymm10..ymm15
    ; round 1/6
    vmulpd ymm10, ymm6, ymm0            ; h0 :=  A6_shr *  B6_shr
    vmovapd yword [h], ymm10            ; store h0
    vmulpd ymm11, ymm6, ymm1            ; h1 :=  A6_shr *  B7_shr
    vmulpd ymm12, ymm6, ymm2            ; h2 :=  A6_shr *  B8_shr
    vmulpd ymm13, ymm6, ymm3            ; h3 :=  A6_shr *  B9_shr
    vmulpd ymm14, ymm6, ymm4            ; h4 :=  A6_shr * B10_shr
    vmulpd ymm15, ymm6, ymm5            ; h5 :=  A6_shr * B11_shr
    vmovapd yword [A6_shr], ymm6        ; spill A6_shr
    ; round 2/6
    vandpd ymm6, ymm9, yword [A+224]    ; load A7_shr
    vmulpd ymm8, ymm6, ymm0
    vaddpd ymm11, ymm11, ymm8           ; h1 +=  A7_shr *  B6_shr
    vmovapd yword [h+32], ymm11         ; store h1
    vmulpd ymm8, ymm6, ymm1
    vaddpd ymm12, ymm12, ymm8           ; h2 +=  A7_shr *  B7_shr
    vmulpd ymm8, ymm6, ymm2
    vaddpd ymm13, ymm13, ymm8           ; h3 +=  A7_shr *  B8_shr
    vmulpd ymm8, ymm6, ymm3
    vaddpd ymm14, ymm14, ymm8           ; h4 +=  A7_shr *  B9_shr
    vmulpd ymm8, ymm6, ymm4
    vaddpd ymm15, ymm15, ymm8           ; h5 +=  A7_shr * B10_shr
    vmulpd ymm10, ymm6, ymm5            ; h6 :=  A7_shr * B11_shr
    ; round 3/6
    vandpd ymm6, ymm9, yword [A+256]    ; load A8_shr
    vmulpd ymm8, ymm6, ymm0
    vaddpd ymm12, ymm12, ymm8           ; h2 +=  A8_shr *  B6_shr
    vmovapd yword [h+64], ymm12         ; store h2
    vmulpd ymm8, ymm6, ymm1
    vaddpd ymm13, ymm13, ymm8           ; h3 +=  A8_shr *  B7_shr
    vmulpd ymm8, ymm6, ymm2
    vaddpd ymm14, ymm14, ymm8           ; h4 +=  A8_shr *  B8_shr
    vmulpd ymm8, ymm6, ymm3
    vaddpd ymm15, ymm15, ymm8           ; h5 +=  A8_shr *  B9_shr
    vmulpd ymm8, ymm6, ymm4
    vaddpd ymm10, ymm10, ymm8           ; h6 +=  A8_shr * B10_shr
    vmulpd ymm11, ymm6, ymm5            ; h7 :=  A8_shr * B11_shr
    ; round 4/6
    vandpd ymm6, ymm9, yword [A+288]    ; load A9_shr
    vmulpd ymm8, ymm6, ymm0
    vaddpd ymm13, ymm13, ymm8           ; h3 +=  A9_shr *  B6_shr
    vmovapd yword [h+96], ymm13         ; store h3
    vmulpd ymm8, ymm6, ymm1
    vaddpd ymm14, ymm14, ymm8           ; h4 +=  A9_shr *  B7_shr
    vmulpd ymm8, ymm6, ymm2
    vaddpd ymm15, ymm15, ymm8           ; h5 +=  A9_shr *  B8_shr
    vmulpd ymm8, ymm6, ymm3
    vaddpd ymm10, ymm10, ymm8           ; h6 +=  A9_shr *  B9_shr
    vmulpd ymm8, ymm6, ymm4
    vaddpd ymm11, ymm11, ymm8           ; h7 +=  A9_shr * B10_shr
    vmulpd ymm12, ymm6, ymm5            ; h8 :=  A9_shr * B11_shr
    ; round 5/6
    vandpd ymm6, ymm9, yword [A+320]    ; load A10_shr
    vmulpd ymm8, ymm6, ymm0
    vaddpd ymm14, ymm14, ymm8           ; h4 += A10_shr *  B6_shr
    vmovapd yword [h+128], ymm14        ; store h4
    vmulpd ymm8, ymm6, ymm1
    vaddpd ymm15, ymm15, ymm8           ; h5 += A10_shr *  B7_shr
    vmulpd ymm8, ymm6, ymm2
    vaddpd ymm10, ymm10, ymm8           ; h6 += A10_shr *  B8_shr
    vmulpd ymm8, ymm6, ymm3
    vaddpd ymm11, ymm11, ymm8           ; h7 += A10_shr *  B9_shr
    vmulpd ymm8, ymm6, ymm4
    vaddpd ymm12, ymm12, ymm8           ; h8 += A10_shr * B10_shr
    vmulpd ymm13, ymm6, ymm5            ; h9 := A10_shr * B11_shr
    ; round 6/6                         ; (A11_shr is already in ymm7)
    vmulpd ymm8, ymm7, ymm0
    vaddpd ymm15, ymm15, ymm8           ; h5 += A11_shr *  B6_shr
    vmovapd yword [h+160], ymm15        ; store h5
    vmulpd ymm8, ymm7, ymm1
    vaddpd ymm10, ymm10, ymm8           ; h6 += A11_shr *  B7_shr
    vmovapd yword [h+192], ymm10        ; store h6
    vmulpd ymm8, ymm7, ymm2
    vaddpd ymm11, ymm11, ymm8           ; h7 += A11_shr *  B8_shr
    vmovapd yword [h+224], ymm11        ; store h7
    vmulpd ymm8, ymm7, ymm3
    vaddpd ymm12, ymm12, ymm8           ; h8 += A11_shr *  B9_shr
    vmovapd yword [h+256], ymm12        ; store h8
    vmulpd ymm8, ymm7, ymm4
    vaddpd ymm13, ymm13, ymm8           ; h9 += A11_shr * B10_shr
    vmovapd yword [h+288], ymm13        ; store h9
    vmulpd ymm14, ymm7, ymm5            ; h10 := A11_shr * B11_shr
    vmovapd yword [A11_shr], ymm7       ; spill A11_shr
    vmovapd yword [h+320], ymm14        ; store h10
    ; At this point, we have A11_shr,B6_shr..B11_shr in registers, A6_shr is spilled to the stack

    ; Compute M_hat and accumulation into C[6]..C[11]
    ;
    ; After each round of M_hat, one of the M_hat values is done, then we have everything we need
    ; to compute the corresponding limb in our product. To reduce pressure on ports 2 and 3 (for
    ; loads), we will compute these values ahead of time (in-between the rounds).
    ;
    ; round 1/6
    vmovapd ymm6, yword [A]             ; load A[0]
    vsubpd ymm6, ymm6, yword [A6_shr]   ; mA0 := A[0] - A6_shr
    vsubpd ymm0, ymm0, yword [B]        ; mB0 :=  B6_shr - B[0]
    vmulpd ymm10, ymm6, ymm0            ; m0 := mA0 * mB0
    vsubpd ymm1, ymm1, yword [B+32]     ; mB1 :=  B7_shr - B[1]
    vmulpd ymm11, ymm6, ymm1            ; m1 := mA0 * mB1
    vsubpd ymm2, ymm2, yword [B+64]     ; mB2 :=  B8_shr - B[2]
    vmulpd ymm12, ymm6, ymm2            ; m2 := mA0 * mB2
    vsubpd ymm3, ymm3, yword [B+96]     ; mB3 :=  B9_shr - B[3]
    vmulpd ymm13, ymm6, ymm3            ; m3 := mA0 * mB3
    vsubpd ymm4, ymm4, yword [B+128]    ; mB4 := B10_shr - B[4]
    vmulpd ymm14, ymm6, ymm4            ; m4 := mA0 * mB4
    vsubpd ymm5, ymm5, yword [B+160]    ; mB5 := B11_shr - B[5]
    vmulpd ymm15, ymm6, ymm5            ; m5 := mA0 * mB5
    ; compute C[6] := l6 + 0x1p+128 * (m0 + l0 + h0) + 0x26p0*h6
    ; TODO(dsprenkels) Benchmark to see if different addition order is faster
    vaddpd ymm10, ymm10, yword [l]
    vaddpd ymm10, ymm10, yword [h]
    vmovapd ymm7, yword [rel .const_1_1p_128]
    vmulpd ymm10, ymm10, ymm7
    vmovapd ymm8, yword [rel .const_38]
    vmulpd ymm6, ymm8, yword [h+192]
    vaddpd ymm6, ymm6, yword [l+192]
    vaddpd ymm10, ymm10, ymm6
    vmovapd yword [C+192], ymm10
    ; round 2/6
    vandpd ymm10, ymm9, yword [A+224]   ; load A7_shr (ymm9 still contains .const_unset_bit59_mask)
    vmovapd ymm6, yword [A+32]          ; load A[1]
    vsubpd ymm6, ymm6, ymm10            ; mA1 := A[1] - A7_shr
    vmulpd ymm10, ymm6, ymm0
    vaddpd ymm11, ymm11, ymm10          ; m1 += mA1 * mB0
    vmulpd ymm10, ymm6, ymm1
    vaddpd ymm12, ymm12, ymm10          ; m2 += mA1 * mB1
    vmulpd ymm10, ymm6, ymm2
    vaddpd ymm13, ymm13, ymm10          ; m3 += mA1 * mB2
    vmulpd ymm10, ymm6, ymm3
    vaddpd ymm14, ymm14, ymm10          ; m4 += mA1 * mB3
    vmulpd ymm10, ymm6, ymm4
    vaddpd ymm15, ymm15, ymm10          ; m5 += mA1 * mB4
    vmulpd ymm10, ymm6, ymm5            ; m6 := mA1 * mB5
    ; compute C[7] := l7 + 0x1p+128 * (m1 + l1 + h1) + 0x26p0*h7
    vaddpd ymm11, ymm11, yword [l+32]
    vaddpd ymm11, ymm11, yword [h+32]
    vmulpd ymm11, ymm11, ymm7
    vmulpd ymm6, ymm8, yword [h+224]
    vaddpd ymm6, ymm6, yword [l+224]
    vaddpd ymm11, ymm11, ymm6
    vmovapd yword [C+224], ymm11
    ; round 3/6
    vandpd ymm11, ymm9, yword [A+256]   ; load A8_shr
    vmovapd ymm6, yword [A+64]          ; load A[2]
    vsubpd ymm6, ymm6, ymm11            ; mA2 := A[2] - A8_shr
    vmulpd ymm11, ymm6, ymm0
    vaddpd ymm12, ymm12, ymm11          ; m2 += mA2 * mB0
    vmulpd ymm11, ymm6, ymm1
    vaddpd ymm13, ymm13, ymm11          ; m3 += mA2 * mB1
    vmulpd ymm11, ymm6, ymm2
    vaddpd ymm14, ymm14, ymm11          ; m4 += mA2 * mB2
    vmulpd ymm11, ymm6, ymm3
    vaddpd ymm15, ymm15, ymm11          ; m5 += mA2 * mB3
    vmulpd ymm11, ymm6, ymm4
    vaddpd ymm10, ymm10, ymm11          ; m6 += mA2 * mB4
    vmulpd ymm11, ymm6, ymm5            ; m7 := mA2 * mB5
    ; compute C[8] := l8 + 0x1p+128 * (m2 + l2 + h2) + 0x26p0*h8
    vaddpd ymm12, ymm12, yword [l+64]
    vaddpd ymm12, ymm12, yword [h+64]
    vmulpd ymm12, ymm12, ymm7
    vmulpd ymm6, ymm8, yword [h+256]
    vaddpd ymm6, ymm6, yword [l+256]
    vaddpd ymm12, ymm12, ymm6
    vmovapd yword [C+256], ymm12
    ; round 4/6
    vandpd ymm12, ymm9, yword [A+288]   ; load A9_shr
    vmovapd ymm6, yword [A+96]          ; load A[3]
    vsubpd ymm6, ymm6, ymm12            ; mA3 := A[3] - A9_shr
    vmulpd ymm12, ymm6, ymm0
    vaddpd ymm13, ymm13, ymm12          ; m3 += mA3 * mB0
    vmulpd ymm12, ymm6, ymm1
    vaddpd ymm14, ymm14, ymm12          ; m4 += mA3 * mB1
    vmulpd ymm12, ymm6, ymm2
    vaddpd ymm15, ymm15, ymm12          ; m5 += mA3 * mB2
    vmulpd ymm12, ymm6, ymm3
    vaddpd ymm10, ymm10, ymm12          ; m6 += mA3 * mB3
    vmulpd ymm12, ymm6, ymm4
    vaddpd ymm11, ymm11, ymm12          ; m7 += mA3 * mB4
    vmulpd ymm12, ymm6, ymm5            ; m8 := mA3 * mB5
    ; compute C[9] = l9 + 0x1p+128 * (m3 + l3 + h3) + 0x26p0*h9
    vaddpd ymm13, ymm13, yword [l+96]
    vaddpd ymm13, ymm13, yword [h+96]
    vmulpd ymm13, ymm13, ymm7
    vmulpd ymm6, ymm8, yword [h+288]
    vaddpd ymm6, ymm6, yword [l+288]
    vaddpd ymm13, ymm13, ymm6
    vmovapd yword [C+288], ymm13
    ; round 5/6
    vandpd ymm13, ymm9, yword [A+320]   ; load A10_shr
    vmovapd ymm6, yword [A+128]         ; load A[4]
    vsubpd ymm6, ymm6, ymm13            ; mA4 := A[4] - A10_shr
    vmulpd ymm13, ymm6, ymm0
    vaddpd ymm14, ymm14, ymm13          ; m4 += mA4 * mB0
    vmulpd ymm13, ymm6, ymm1
    vaddpd ymm15, ymm15, ymm13          ; m5 += mA4 * mB1
    vmulpd ymm13, ymm6, ymm2
    vaddpd ymm10, ymm10, ymm13          ; m6 += mA4 * mB2
    vmulpd ymm13, ymm6, ymm3
    vaddpd ymm11, ymm11, ymm13          ; m7 += mA4 * mB3
    vmulpd ymm13, ymm6, ymm4
    vaddpd ymm12, ymm12, ymm13          ; m8 += mA4 * mB4
    vmulpd ymm13, ymm6, ymm5            ; m9 := mA4 * mB5
    ; compute C[10] := l10 + 0x1p+128 * (m4 + l4 + h4) + 0x26p0*h10
    vaddpd ymm14, ymm14, yword [l+128]
    vaddpd ymm14, ymm14, yword [h+128]
    vmulpd ymm14, ymm14, ymm7
    vmulpd ymm6, ymm8, yword [h+320]
    vaddpd ymm6, ymm6, yword [l+320]
    vaddpd ymm14, ymm14, ymm6
    vmovapd yword [C+320], ymm14
    ; round 6/6
    vmovapd ymm6, yword [A+160]         ; load A[5]
    vsubpd ymm6, ymm6, yword [A11_shr]  ; mA5 := A[5] - A11_shr
    vmulpd ymm14, ymm6, ymm0
    vaddpd ymm15, ymm15, ymm14          ; m5 += mA5 * mB0
    vmulpd ymm14, ymm6, ymm1
    vaddpd ymm10, ymm10, ymm14          ; m6 += mA5 * mB1
    vmulpd ymm14, ymm6, ymm2
    vaddpd ymm11, ymm11, ymm14          ; m7 += mA5 * mB2
    vmulpd ymm14, ymm6, ymm3
    vaddpd ymm12, ymm12, ymm14          ; m8 += mA5 * mB3
    vmulpd ymm14, ymm6, ymm4
    vaddpd ymm13, ymm13, ymm14          ; m9 += mA5 * mB4
    vmulpd ymm14, ymm6, ymm5            ; m10 := mA5 * mB5
    ; compute C[11] := 0x1p+128 * (m5 + l5 + h5)
    vaddpd ymm15, ymm15, yword [l+160]
    vaddpd ymm15, ymm15, yword [h+160]
    vmulpd ymm15, ymm15, ymm7
    vmovapd yword [C+352], ymm15

    ; compute C[{0..5}]
    vmovapd ymm6, yword [rel .const_1_1p_neg128]
    ; TODO(dsprenkels) Also try the masking optimisation here
    vaddpd ymm10, ymm10, yword [l+192]
    vaddpd ymm10, ymm10, yword [h+192]
    vmulpd ymm10, ymm10, ymm6
    vaddpd ymm10, ymm10, yword [h]
    vmulpd ymm10, ymm10, ymm8
    vaddpd ymm10, ymm10, yword [l]
    vaddpd ymm11, ymm11, yword [l+224]
    vaddpd ymm11, ymm11, yword [h+224]
    vmulpd ymm11, ymm11, ymm6
    vaddpd ymm11, ymm11, yword [h+32]
    vmulpd ymm11, ymm11, ymm8
    vaddpd ymm11, ymm11, yword [l+32]
    vaddpd ymm12, ymm12, yword [l+256]
    vaddpd ymm12, ymm12, yword [h+256]
    vmulpd ymm12, ymm12, ymm6
    vaddpd ymm12, ymm12, yword [h+64]
    vmulpd ymm12, ymm12, ymm8
    vaddpd ymm12, ymm12, yword [l+64]
    vaddpd ymm13, ymm13, yword [l+288]
    vaddpd ymm13, ymm13, yword [h+288]
    vmulpd ymm13, ymm13, ymm6
    vaddpd ymm13, ymm13, yword [h+96]
    vmulpd ymm13, ymm13, ymm8
    vaddpd ymm13, ymm13, yword [l+96]
    vaddpd ymm14, ymm14, yword [l+320]
    vaddpd ymm14, ymm14, yword [h+320]
    vmulpd ymm14, ymm14, ymm6
    vaddpd ymm14, ymm14, yword [h+128]
    vmulpd ymm14, ymm14, ymm8
    vaddpd ymm14, ymm14, yword [l+128]
    vmulpd ymm15, ymm8, yword [h+160]
    vaddpd ymm15, ymm15, yword [l+160]

    %pop fe12x4_mul_body_1_ctx
%endmacro

%macro fe12x4_mul_body_2 4
    ; Multiply two field elements using subtractive karatsuba method: body
    ;
    ; Arguments:
    ;   - %0:       address to the product of A and B
    ;   - %1:       two vectorized field element operand A
    ;   - %2:       two vectorized field element operand B
    ;   - %3:       address to 768 (24*32) aligned bytes of scratch space
    %push fe12x4_mul_body_ctx

    %xdefine C          %1
    %xdefine A          %2
    %xdefine B          %3
    %xdefine l          %4
    %xdefine A6_shr     %4 + 32*11
    %xdefine h          %4 + 32*12
    %xdefine A11_shr    %4 + 32*23

    ; compute L
    ; ymm9 will stores intermediate values, ymm10..ymm15 will stores the accumulators
    ; round 1/6
    vmulpd ymm10, ymm6, ymm0        ; l0 := A[0] * B[0]
    vmovapd yword [l], ymm10        ; store l[0]
    vmulpd ymm11, ymm6, ymm1        ; l1 := A[0] * B[1]
    vmulpd ymm12, ymm6, ymm2        ; l2 := A[0] * B[2]
    vmulpd ymm13, ymm6, ymm3        ; l3 := A[0] * B[3]
    vmovapd ymm4, yword [B+128]     ; load B[4]
    vmulpd ymm14, ymm6, ymm4        ; l4 := A[0] * B[4]
    vmovapd ymm5, yword [B+160]     ; load B[5]
    vmulpd ymm15, ymm6, ymm5        ; l5 := A[0] * B[5]
    ; round 2/6
    vmulpd ymm9, ymm7, ymm0
    vaddpd ymm11, ymm11, ymm9       ; l1 += A[1] * B[0]
    vmovapd yword [l+32], ymm11     ; store l1
    vmulpd ymm9, ymm7, ymm1
    vaddpd ymm12, ymm12, ymm9       ; l2 += A[1] * B[1]
    vmulpd ymm9, ymm7, ymm2
    vaddpd ymm13, ymm13, ymm9       ; l3 += A[1] * B[2]
    vmulpd ymm9, ymm7, ymm3
    vaddpd ymm14, ymm14, ymm9       ; l4 += A[1] * B[3]
    vmulpd ymm9, ymm7, ymm4
    vaddpd ymm15, ymm15, ymm9       ; l5 += A[1] * B[4]
    vmulpd ymm10, ymm7, ymm5        ; l6 := A[1] * B[5]
    ; round 3/6
    vmovapd ymm8, yword [A+64]      ; load A[2]
    vmulpd ymm9, ymm8, ymm0
    vaddpd ymm12, ymm12, ymm9       ; l2 += A[2] * B[0]
    vmovapd yword [l+64], ymm12     ; store l2
    vmulpd ymm9, ymm8, ymm1
    vaddpd ymm13, ymm13, ymm9       ; l3 += A[2] * B[1]
    vmulpd ymm9, ymm8, ymm2
    vaddpd ymm14, ymm14, ymm9       ; l4 += A[2] * B[2]
    vmulpd ymm9, ymm8, ymm3
    vaddpd ymm15, ymm15, ymm9       ; l5 += A[2] * B[3]
    vmulpd ymm9, ymm8, ymm4
    vaddpd ymm10, ymm10, ymm9       ; l6 += A[2] * B[4]
    vmulpd ymm11, ymm8, ymm5        ; l7 := A[2] * B[5]
    ; round 4/6
    vmovapd ymm6, yword [A+96]      ; load A[3]
    vmulpd ymm9, ymm6, ymm0
    vaddpd ymm13, ymm13, ymm9       ; l3 += A[3] * B[0]
    vmovapd yword [l+96], ymm13     ; store l3
    vmulpd ymm9, ymm6, ymm1
    vaddpd ymm14, ymm14, ymm9       ; l4 += A[3] * B[1]
    vmulpd ymm9, ymm6, ymm2
    vaddpd ymm15, ymm15, ymm9       ; l5 += A[3] * B[2]
    vmulpd ymm9, ymm6, ymm3
    vaddpd ymm10, ymm10, ymm9       ; l6 += A[3] * B[3]
    vmulpd ymm9, ymm6, ymm4
    vaddpd ymm11, ymm11, ymm9       ; l7 += A[3] * B[4]
    vmulpd ymm12, ymm6, ymm5        ; l8 := A[3] * B[5]
    ; round 5/6
    vmovapd ymm7, yword [A+128]     ; load A[4]
    vmulpd ymm9, ymm7, ymm0
    vaddpd ymm14, ymm14, ymm9       ; l4 += A[4] * B[0]
    vmovapd yword [l+128], ymm14    ; store l4
    vmulpd ymm9, ymm7, ymm1
    vaddpd ymm15, ymm15, ymm9       ; l5 += A[4] * B[1]
    vmulpd ymm9, ymm7, ymm2
    vaddpd ymm10, ymm10, ymm9       ; l6 += A[4] * B[2]
    vmulpd ymm9, ymm7, ymm3
    vaddpd ymm11, ymm11, ymm9       ; l7 += A[4] * B[3]
    vmulpd ymm9, ymm7, ymm4
    vaddpd ymm12, ymm12, ymm9       ; l8 += A[4] * B[4]
    vmulpd ymm13, ymm7, ymm5        ; l9 := A[4] * B[5]
    ; round 6/6
    vmovapd ymm8, yword [A+160]     ; load A[5]
    vmulpd ymm9, ymm8, ymm0
    vaddpd ymm15, ymm15, ymm9       ; l5 += A[5] * B[0]
    vmovapd yword [l+160], ymm15    ; store l5
    vmulpd ymm9, ymm8, ymm1
    vaddpd ymm10, ymm10, ymm9       ; l6 += A[5] * B[1]
    vmovapd yword [l+192], ymm10    ; store l6
    vmulpd ymm9, ymm8, ymm2
    vaddpd ymm11, ymm11, ymm9       ; l7 += A[5] * B[2]
    vmovapd yword [l+224], ymm11    ; store l7
    vmulpd ymm9, ymm8, ymm3
    vaddpd ymm12, ymm12, ymm9       ; l8 += A[5] * B[3]
    vmovapd yword [l+256], ymm12    ; store l8
    vmulpd ymm9, ymm8, ymm4
    vaddpd ymm13, ymm13, ymm9       ; l9 += A[5] * B[4]
    vmovapd yword [l+288], ymm13    ; store l9
    vmulpd ymm14, ymm8, ymm5        ; l10:= A[5] * B[5]
    vmovapd yword [l+320], ymm14    ; store l10

    ; compute H
    ; We will:
    ;   - precompute the A6_shr,A11_shr,Bx_shr values and,
    ;   - compute the A7_shr..A10_shr values on the fly, because they can be done in parallel
    ;     with vmulpd instruction.
    ;
    ; In this part of the code I will apply a really specific optimisation: For {A,B}x7-{A,B}x10,
    ; we know for sure that they are:
    ;   - either 0, and so exponent part of the double is '0b00000000000'
    ;   - 0 modulo 2^149 and smaller than 2^237 => as such, the 7'th exponent bit is always set.
    ;     Thus we can use a mask operation for these values to divide them by 2*128.
    ;
    vmovapd ymm8, yword [rel .const_1_1p_neg128]
    vmovapd ymm9, yword [rel .const_unset_bit59_mask]
    vmulpd ymm6, ymm8, yword [A+192]   ;  A6_shr = 0x1p-128 * A[ 6];
    vmulpd ymm0, ymm8, yword [B+192]   ;  B6_shr = 0x1p-128 * B[ 6];
    vandpd ymm1, ymm9, yword [B+224]   ;  B7_shr = unset_bit59(B[7]);
    vandpd ymm2, ymm9, yword [B+256]   ;  B8_shr = unset_bit59(B[8]);
    vandpd ymm3, ymm9, yword [B+288]   ;  B9_shr = unset_bit59(B[9]);
    vandpd ymm4, ymm9, yword [B+320]   ; B10_shr = unset_bit59(B[10]);
    vmulpd ymm5, ymm8, yword [B+352]   ; B11_shr = 0x1p-128 * B[11];
    vmulpd ymm7, ymm8, yword [A+352]   ; A11_shr = 0x1p-128 * A[11];

    ; TODO(dsprenkels) We don't actually need to spill A6_shr, I think. Every round we rotate by
    ; one register. I.e. in round 2, the register ymm10 is only used in the end, so we can safely
    ; use ymm10 for temporary values during that round. Now we have an extra register in which we
    ; can retain A6_shr (or some other useful values).

    nop
    ; Just as in the computation of L, we will store the accumulators (h) in ymm10..ymm15
    ; round 1/6
    vmulpd ymm10, ymm6, ymm0            ; h0 :=  A6_shr *  B6_shr
    vmovapd yword [h], ymm10            ; store h0
    vmulpd ymm11, ymm6, ymm1            ; h1 :=  A6_shr *  B7_shr
    vmulpd ymm12, ymm6, ymm2            ; h2 :=  A6_shr *  B8_shr
    vmulpd ymm13, ymm6, ymm3            ; h3 :=  A6_shr *  B9_shr
    vmulpd ymm14, ymm6, ymm4            ; h4 :=  A6_shr * B10_shr
    vmulpd ymm15, ymm6, ymm5            ; h5 :=  A6_shr * B11_shr
    vmovapd yword [A6_shr], ymm6        ; spill A6_shr
    ; round 2/6
    vandpd ymm6, ymm9, yword [A+224]    ; load A7_shr
    vmulpd ymm8, ymm6, ymm0
    vaddpd ymm11, ymm11, ymm8           ; h1 +=  A7_shr *  B6_shr
    vmovapd yword [h+32], ymm11         ; store h1
    vmulpd ymm8, ymm6, ymm1
    vaddpd ymm12, ymm12, ymm8           ; h2 +=  A7_shr *  B7_shr
    vmulpd ymm8, ymm6, ymm2
    vaddpd ymm13, ymm13, ymm8           ; h3 +=  A7_shr *  B8_shr
    vmulpd ymm8, ymm6, ymm3
    vaddpd ymm14, ymm14, ymm8           ; h4 +=  A7_shr *  B9_shr
    vmulpd ymm8, ymm6, ymm4
    vaddpd ymm15, ymm15, ymm8           ; h5 +=  A7_shr * B10_shr
    vmulpd ymm10, ymm6, ymm5            ; h6 :=  A7_shr * B11_shr
    ; round 3/6
    vandpd ymm6, ymm9, yword [A+256]    ; load A8_shr
    vmulpd ymm8, ymm6, ymm0
    vaddpd ymm12, ymm12, ymm8           ; h2 +=  A8_shr *  B6_shr
    vmovapd yword [h+64], ymm12         ; store h2
    vmulpd ymm8, ymm6, ymm1
    vaddpd ymm13, ymm13, ymm8           ; h3 +=  A8_shr *  B7_shr
    vmulpd ymm8, ymm6, ymm2
    vaddpd ymm14, ymm14, ymm8           ; h4 +=  A8_shr *  B8_shr
    vmulpd ymm8, ymm6, ymm3
    vaddpd ymm15, ymm15, ymm8           ; h5 +=  A8_shr *  B9_shr
    vmulpd ymm8, ymm6, ymm4
    vaddpd ymm10, ymm10, ymm8           ; h6 +=  A8_shr * B10_shr
    vmulpd ymm11, ymm6, ymm5            ; h7 :=  A8_shr * B11_shr
    ; round 4/6
    vandpd ymm6, ymm9, yword [A+288]    ; load A9_shr
    vmulpd ymm8, ymm6, ymm0
    vaddpd ymm13, ymm13, ymm8           ; h3 +=  A9_shr *  B6_shr
    vmovapd yword [h+96], ymm13         ; store h3
    vmulpd ymm8, ymm6, ymm1
    vaddpd ymm14, ymm14, ymm8           ; h4 +=  A9_shr *  B7_shr
    vmulpd ymm8, ymm6, ymm2
    vaddpd ymm15, ymm15, ymm8           ; h5 +=  A9_shr *  B8_shr
    vmulpd ymm8, ymm6, ymm3
    vaddpd ymm10, ymm10, ymm8           ; h6 +=  A9_shr *  B9_shr
    vmulpd ymm8, ymm6, ymm4
    vaddpd ymm11, ymm11, ymm8           ; h7 +=  A9_shr * B10_shr
    vmulpd ymm12, ymm6, ymm5            ; h8 :=  A9_shr * B11_shr
    ; round 5/6
    vandpd ymm6, ymm9, yword [A+320]    ; load A10_shr
    vmulpd ymm8, ymm6, ymm0
    vaddpd ymm14, ymm14, ymm8           ; h4 += A10_shr *  B6_shr
    vmovapd yword [h+128], ymm14        ; store h4
    vmulpd ymm8, ymm6, ymm1
    vaddpd ymm15, ymm15, ymm8           ; h5 += A10_shr *  B7_shr
    vmulpd ymm8, ymm6, ymm2
    vaddpd ymm10, ymm10, ymm8           ; h6 += A10_shr *  B8_shr
    vmulpd ymm8, ymm6, ymm3
    vaddpd ymm11, ymm11, ymm8           ; h7 += A10_shr *  B9_shr
    vmulpd ymm8, ymm6, ymm4
    vaddpd ymm12, ymm12, ymm8           ; h8 += A10_shr * B10_shr
    vmulpd ymm13, ymm6, ymm5            ; h9 := A10_shr * B11_shr
    ; round 6/6                         ; (A11_shr is already in ymm7)
    vmulpd ymm8, ymm7, ymm0
    vaddpd ymm15, ymm15, ymm8           ; h5 += A11_shr *  B6_shr
    vmovapd yword [h+160], ymm15        ; store h5
    vmulpd ymm8, ymm7, ymm1
    vaddpd ymm10, ymm10, ymm8           ; h6 += A11_shr *  B7_shr
    vmovapd yword [h+192], ymm10        ; store h6
    vmulpd ymm8, ymm7, ymm2
    vaddpd ymm11, ymm11, ymm8           ; h7 += A11_shr *  B8_shr
    vmovapd yword [h+224], ymm11        ; store h7
    vmulpd ymm8, ymm7, ymm3
    vaddpd ymm12, ymm12, ymm8           ; h8 += A11_shr *  B9_shr
    vmovapd yword [h+256], ymm12        ; store h8
    vmulpd ymm8, ymm7, ymm4
    vaddpd ymm13, ymm13, ymm8           ; h9 += A11_shr * B10_shr
    vmovapd yword [h+288], ymm13        ; store h9
    vmulpd ymm14, ymm7, ymm5            ; h10 := A11_shr * B11_shr
    vmovapd yword [A11_shr], ymm7       ; spill A11_shr
    vmovapd yword [h+320], ymm14        ; store h10
    ; At this point, we have A11_shr,B6_shr..B11_shr in registers, A6_shr is spilled to the stack

    ; Compute M_hat and accumulation into C[6]..C[11]
    ;
    ; After each round of M_hat, one of the M_hat values is done, then we have everything we need
    ; to compute the corresponding limb in our product. To reduce pressure on ports 2 and 3 (for
    ; loads), we will compute these values ahead of time (in-between the rounds).
    ;
    ; round 1/6
    nop
    vmovapd ymm6, yword [A]             ; load A[0]
    vmovapd ymm7, yword [A6_shr]
    vsubpd ymm6, ymm6, ymm7             ; mA0 := A[0] - A6_shr
    vmovapd ymm7, yword [B]
    vsubpd ymm0, ymm0, ymm7             ; mB0 :=  B6_shr - B[0]
    vmulpd ymm10, ymm6, ymm0            ; m0 := mA0 * mB0
    vmovapd ymm7, yword [B+32]
    vsubpd ymm1, ymm1, ymm7             ; mB1 :=  B7_shr - B[1]
    vmulpd ymm11, ymm6, ymm1            ; m1 := mA0 * mB1
    vmovapd ymm7, yword [B+64]
    vsubpd ymm2, ymm2, ymm7             ; mB2 :=  B8_shr - B[2]
    vmulpd ymm12, ymm6, ymm2            ; m2 := mA0 * mB2
    vmovapd ymm7, yword [B+96]
    vsubpd ymm3, ymm3, ymm7             ; mB3 :=  B9_shr - B[3]
    vmulpd ymm13, ymm6, ymm3            ; m3 := mA0 * mB3
    vmovapd ymm7, yword [B+128]
    vsubpd ymm4, ymm4, ymm7             ; mB4 := B10_shr - B[4]
    vmulpd ymm14, ymm6, ymm4            ; m4 := mA0 * mB4
    vmovapd ymm7, yword [B+160]
    vsubpd ymm5, ymm5, ymm7             ; mB5 := B11_shr - B[5]
    vmulpd ymm15, ymm6, ymm5            ; m5 := mA0 * mB5
    ; compute C[6] := l6 + 0x1p+128 * (m0 + l0 + h0) + 0x26p0*h6
    vaddpd ymm10, ymm10, yword [l]
    vaddpd ymm10, ymm10, yword [h]
    vmovapd ymm7, yword [rel .const_1_1p_128]
    vmulpd ymm10, ymm10, ymm7
    vmovapd ymm8, yword [rel .const_38]
    vmulpd ymm6, ymm8, yword [h+192]
    vaddpd ymm6, ymm6, yword [l+192]
    vaddpd ymm10, ymm10, ymm6
    vmovapd yword [C+192], ymm10
    ; round 2/6
    vandpd ymm10, ymm9, yword [A+224]   ; load A7_shr (ymm9 still contains .const_unset_bit59_mask)
    vmovapd ymm6, yword [A+32]          ; load A[1]
    vsubpd ymm6, ymm6, ymm10            ; mA1 := A[1] - A7_shr
    vmulpd ymm10, ymm6, ymm0
    vaddpd ymm11, ymm11, ymm10          ; m1 += mA1 * mB0
    vmulpd ymm10, ymm6, ymm1
    vaddpd ymm12, ymm12, ymm10          ; m2 += mA1 * mB1
    vmulpd ymm10, ymm6, ymm2
    vaddpd ymm13, ymm13, ymm10          ; m3 += mA1 * mB2
    vmulpd ymm10, ymm6, ymm3
    vaddpd ymm14, ymm14, ymm10          ; m4 += mA1 * mB3
    vmulpd ymm10, ymm6, ymm4
    vaddpd ymm15, ymm15, ymm10          ; m5 += mA1 * mB4
    vmulpd ymm10, ymm6, ymm5            ; m6 := mA1 * mB5
    ; compute C[7] := l7 + 0x1p+128 * (m1 + l1 + h1) + 0x26p0*h7
    vaddpd ymm11, ymm11, yword [l+32]
    vaddpd ymm11, ymm11, yword [h+32]
    vmulpd ymm11, ymm11, ymm7
    vmulpd ymm6, ymm8, yword [h+224]
    vaddpd ymm6, ymm6, yword [l+224]
    vaddpd ymm11, ymm11, ymm6
    vmovapd yword [C+224], ymm11
    ; round 3/6
    vandpd ymm11, ymm9, yword [A+256]   ; load A8_shr
    vmovapd ymm6, yword [A+64]          ; load A[2]
    vsubpd ymm6, ymm6, ymm11            ; mA2 := A[2] - A8_shr
    vmulpd ymm11, ymm6, ymm0
    vaddpd ymm12, ymm12, ymm11          ; m2 += mA2 * mB0
    vmulpd ymm11, ymm6, ymm1
    vaddpd ymm13, ymm13, ymm11          ; m3 += mA2 * mB1
    vmulpd ymm11, ymm6, ymm2
    vaddpd ymm14, ymm14, ymm11          ; m4 += mA2 * mB2
    vmulpd ymm11, ymm6, ymm3
    vaddpd ymm15, ymm15, ymm11          ; m5 += mA2 * mB3
    vmulpd ymm11, ymm6, ymm4
    vaddpd ymm10, ymm10, ymm11          ; m6 += mA2 * mB4
    vmulpd ymm11, ymm6, ymm5            ; m7 := mA2 * mB5
    ; compute C[8] := l8 + 0x1p+128 * (m2 + l2 + h2) + 0x26p0*h8
    vaddpd ymm12, ymm12, yword [l+64]
    vaddpd ymm12, ymm12, yword [h+64]
    vmulpd ymm12, ymm12, ymm7
    vmulpd ymm6, ymm8, yword [h+256]
    vaddpd ymm6, ymm6, yword [l+256]
    vaddpd ymm12, ymm12, ymm6
    vmovapd yword [C+256], ymm12
    ; round 4/6
    vandpd ymm12, ymm9, yword [A+288]   ; load A9_shr
    vmovapd ymm6, yword [A+96]          ; load A[3]
    vsubpd ymm6, ymm6, ymm12            ; mA3 := A[3] - A9_shr
    vmulpd ymm12, ymm6, ymm0
    vaddpd ymm13, ymm13, ymm12          ; m3 += mA3 * mB0
    vmulpd ymm12, ymm6, ymm1
    vaddpd ymm14, ymm14, ymm12          ; m4 += mA3 * mB1
    vmulpd ymm12, ymm6, ymm2
    vaddpd ymm15, ymm15, ymm12          ; m5 += mA3 * mB2
    vmulpd ymm12, ymm6, ymm3
    vaddpd ymm10, ymm10, ymm12          ; m6 += mA3 * mB3
    vmulpd ymm12, ymm6, ymm4
    vaddpd ymm11, ymm11, ymm12          ; m7 += mA3 * mB4
    vmulpd ymm12, ymm6, ymm5            ; m8 := mA3 * mB5
    ; compute C[9] = l9 + 0x1p+128 * (m3 + l3 + h3) + 0x26p0*h9
    vaddpd ymm13, ymm13, yword [l+96]
    vaddpd ymm13, ymm13, yword [h+96]
    vmulpd ymm13, ymm13, ymm7
    vmulpd ymm6, ymm8, yword [h+288]
    vaddpd ymm6, ymm6, yword [l+288]
    vaddpd ymm13, ymm13, ymm6
    vmovapd yword [C+288], ymm13
    ; round 5/6
    vandpd ymm13, ymm9, yword [A+320]   ; load A10_shr
    vmovapd ymm6, yword [A+128]         ; load A[4]
    vsubpd ymm6, ymm6, ymm13            ; mA4 := A[4] - A10_shr
    vmulpd ymm13, ymm6, ymm0
    vaddpd ymm14, ymm14, ymm13          ; m4 += mA4 * mB0
    vmulpd ymm13, ymm6, ymm1
    vaddpd ymm15, ymm15, ymm13          ; m5 += mA4 * mB1
    vmulpd ymm13, ymm6, ymm2
    vaddpd ymm10, ymm10, ymm13          ; m6 += mA4 * mB2
    vmulpd ymm13, ymm6, ymm3
    vaddpd ymm11, ymm11, ymm13          ; m7 += mA4 * mB3
    vmulpd ymm13, ymm6, ymm4
    vaddpd ymm12, ymm12, ymm13          ; m8 += mA4 * mB4
    vmulpd ymm13, ymm6, ymm5            ; m9 := mA4 * mB5
    ; compute C[10] := l10 + 0x1p+128 * (m4 + l4 + h4) + 0x26p0*h10
    vaddpd ymm14, ymm14, yword [l+128]
    vaddpd ymm14, ymm14, yword [h+128]
    vmulpd ymm14, ymm14, ymm7
    vmulpd ymm6, ymm8, yword [h+320]
    vaddpd ymm6, ymm6, yword [l+320]
    vaddpd ymm14, ymm14, ymm6
    vmovapd yword [C+320], ymm14
    ; round 6/6
    vmovapd ymm6, yword [A+160]         ; load A[5]
    vsubpd ymm6, ymm6, yword [A11_shr]  ; mA5 := A[5] - A11_shr
    vmulpd ymm14, ymm6, ymm0
    vaddpd ymm15, ymm15, ymm14          ; m5 += mA5 * mB0
    vmulpd ymm14, ymm6, ymm1
    vaddpd ymm10, ymm10, ymm14          ; m6 += mA5 * mB1
    vmulpd ymm14, ymm6, ymm2
    vaddpd ymm11, ymm11, ymm14          ; m7 += mA5 * mB2
    vmulpd ymm14, ymm6, ymm3
    vaddpd ymm12, ymm12, ymm14          ; m8 += mA5 * mB3
    vmulpd ymm14, ymm6, ymm4
    vaddpd ymm13, ymm13, ymm14          ; m9 += mA5 * mB4
    vmulpd ymm14, ymm6, ymm5            ; m10 := mA5 * mB5
    ; compute C[11] := 0x1p+128 * (m5 + l5 + h5)
    vaddpd ymm15, ymm15, yword [l+160]
    vaddpd ymm15, ymm15, yword [h+160]
    vmulpd ymm15, ymm15, ymm7
    vmovapd yword [C+352], ymm15

    ; compute C[{0..5}]
    vmovapd ymm6, yword [rel .const_1_1p_neg128]
    ; TODO(dsprenkels) Also try the masking optimisation here
    vaddpd ymm10, ymm10, yword [l+192]
    vaddpd ymm10, ymm10, yword [h+192]
    vmulpd ymm10, ymm10, ymm6
    vaddpd ymm10, ymm10, yword [h]
    vmulpd ymm10, ymm10, ymm8
    vaddpd ymm0, ymm10, yword [l]
    vaddpd ymm11, ymm11, yword [l+224]
    vaddpd ymm11, ymm11, yword [h+224]
    vmulpd ymm11, ymm11, ymm6
    vaddpd ymm11, ymm11, yword [h+32]
    vmulpd ymm11, ymm11, ymm8
    vaddpd ymm1, ymm11, yword [l+32]
    vaddpd ymm12, ymm12, yword [l+256]
    vaddpd ymm12, ymm12, yword [h+256]
    vmulpd ymm12, ymm12, ymm6
    vaddpd ymm12, ymm12, yword [h+64]
    vmulpd ymm12, ymm12, ymm8
    vaddpd ymm2, ymm12, yword [l+64]
    vaddpd ymm13, ymm13, yword [l+288]
    vaddpd ymm13, ymm13, yword [h+288]
    vmulpd ymm13, ymm13, ymm6
    vaddpd ymm13, ymm13, yword [h+96]
    vmulpd ymm13, ymm13, ymm8
    vaddpd ymm3, ymm13, yword [l+96]
    vaddpd ymm14, ymm14, yword [l+320]
    vaddpd ymm14, ymm14, yword [h+320]
    vmulpd ymm14, ymm14, ymm6
    vaddpd ymm14, ymm14, yword [h+128]
    vmulpd ymm14, ymm14, ymm8
    vaddpd ymm4, ymm14, yword [l+128]
    vmulpd ymm15, ymm8, yword [h+160]
    vaddpd ymm5, ymm15, yword [l+160]

    %pop fe12x4_mul_body_ctx
%endmacro


section .text

fe12_mul_asm:
    lea rdi, [rel scratch_space]
    lea rsi, [rel scratch_space+384]
    bench_prologue
    lea rdx, [rel scratch_space+768]
    ; Multiply two field elements using subtractive karatsuba
    ;
    ; Input:  two vectorized field elements [rsi], [rdx]
    ; Output: the uncarried product of the two inputs [rdi]
    ;
    ; Precondition: TODO
    ; Postcondition: TODO
    ;
    ; Stack layout:
    ;   - [rsp] up to [rsp+192] contains Ax_shr
    ;   - [rsp+192] up to [rsp+384] contains Bx_shr
    ;   - [rsp+384] up to [rsp+576] contains mAx
    ;   - [rsp+576] up to [rsp+768] contains mBx
    ;   - [rsp+768] up to [rsp+1120] contains the `l` values
    ;   - [rsp+1120] up to [rsp+1472] contains the `m` values
    ;   - [rsp+1472] up to [rsp+1824] contains the `h` values
    %define A rsi
    %define B rdx
    %define C rdi
    %define A6_shr rsp-128
    %define A11_shr rsp-96
    %define l rsp-64
    %define h rsp+288

    ; build stack frame
    push rbp
    mov rbp, rsp
    and rsp, -32
    sub rsp, 640

    fe12x4_mul_body_1 C, A, B, (rsp-128)

    ; store C[{0..5}]
    vmovapd yword [C], ymm10
    vmovapd yword [C+32], ymm11
    vmovapd yword [C+64], ymm12
    vmovapd yword [C+96], ymm13
    vmovapd yword [C+128], ymm14
    vmovapd yword [C+160], ymm15

    ; restore stack frame
    mov rsp, rbp
    pop rbp
    bench_epilogue
    ret

section .rodata

align 32, db 0
.const_unset_bit59_mask: times 4 dq 0xF7FFFFFFFFFFFFFF
.const_1_1p_neg128: times 4 dq 0x1p-128
.const_1_1p_128: times 4 dq 0x1p+128
.const_38: times 4 dq 0x26p0

section .text

fe12_mul_asm_v2:
    lea rdi, [rel scratch_space]
    lea rsi, [rel scratch_space+384]
    bench_prologue
    lea rdx, [rel scratch_space+768]
    ; Multiply two field elements using subtractive karatsuba
    ;
    ; Input:  two vectorized field elements [rsi], [rdx]
    ; Output: the uncarried product of the two inputs [rdi]
    ;
    ; Precondition: TODO
    ; Postcondition: TODO
    ;
    ; Stack layout:
    ;   - [rsp] up to [rsp+192] contains Ax_shr
    ;   - [rsp+192] up to [rsp+384] contains Bx_shr
    ;   - [rsp+384] up to [rsp+576] contains mAx
    ;   - [rsp+576] up to [rsp+768] contains mBx
    ;   - [rsp+768] up to [rsp+1120] contains the `l` values
    ;   - [rsp+1120] up to [rsp+1472] contains the `m` values
    ;   - [rsp+1472] up to [rsp+1824] contains the `h` values
    %define A rsi
    %define B rdx
    %define C rdi
    %define A6_shr rsp-128
    %define A11_shr rsp-96
    %define l rsp-64
    %define h rsp+288

    ; build stack frame
    push rbp
    mov rbp, rsp
    and rsp, -32
    sub rsp, 640

    fe12x4_mul_body_2 C, A, B, (rsp-128)

    ; store C[{0..5}]
    vmovapd yword [C], ymm10
    vmovapd yword [C+32], ymm11
    vmovapd yword [C+64], ymm12
    vmovapd yword [C+96], ymm13
    vmovapd yword [C+128], ymm14
    vmovapd yword [C+160], ymm15

    ; restore stack frame
    mov rsp, rbp
    pop rbp
    bench_epilogue
    ret

section .rodata

align 32, db 0
.const_unset_bit59_mask: times 4 dq 0xF7FFFFFFFFFFFFFF
.const_1_1p_neg128: times 4 dq 0x1p-128
.const_1_1p_128: times 4 dq 0x1p+128
.const_38: times 4 dq 0x26p0

section .text

fe12_mul_gcc:
  lea rdi, [rel scratch_space]
  lea rsi, [rel scratch_space+384]
  bench_prologue
  lea rdx, [rel scratch_space+768]
  push rbp
  mov rbp, rsp
  and rsp, -32
  sub rsp, 1000
  vmovapd ymm12, yword [rdx+32]
  vmovapd ymm11, yword [rsi+32]
  vmovapd ymm0, yword [rsi]
  vmovapd yword [rsp+232], ymm12
  vmovapd ymm6, yword [rdx]
  vmovapd yword [rsp+72], ymm11
  vmulpd ymm5, ymm12, ymm0
  vmovapd ymm10, yword [rdx+64]
  vmovapd yword [rsp+296], ymm0
  vmovapd ymm7, ymm6
  vmulpd ymm2, ymm6, ymm0
  vmulpd ymm4, ymm11, ymm6
  vaddpd ymm6, ymm4, ymm5
  vmulpd ymm3, ymm10, ymm0
  vmovapd ymm9, yword [rdx+96]
  vmulpd ymm5, ymm11, ymm10
  vmovapd yword [rsp+904], ymm2
  vmovapd yword [rsp+264], ymm7
  vmovapd ymm8, yword [rsi+64]
  vmovapd ymm13, yword [rdx+128]
  vmulpd ymm2, ymm9, ymm0
  vmulpd ymm4, ymm11, ymm9
  vaddpd ymm2, ymm5, ymm2
  vmovapd yword [rsp+872], ymm6
  vmulpd ymm6, ymm11, ymm12
  vaddpd ymm6, ymm6, ymm3
  vmovapd ymm14, yword [rdx+160]
  vmulpd ymm1, ymm13, ymm0
  vaddpd ymm4, ymm4, ymm1
  vmulpd ymm1, ymm8, ymm7
  vmulpd ymm3, ymm11, ymm13
  vmulpd ymm0, ymm14, ymm0
  vaddpd ymm3, ymm3, ymm0
  vmulpd ymm5, ymm8, ymm12
  vmulpd ymm0, ymm11, ymm14
  vmovapd yword [rsp+168], ymm9
  vaddpd ymm1, ymm1, ymm6
  vmovapd ymm6, yword [rsi+96]
  vmovapd yword [rsp+200], ymm10
  vaddpd ymm5, ymm5, ymm2
  vmulpd ymm2, ymm8, ymm9
  vaddpd ymm3, ymm2, ymm3
  vmulpd ymm2, ymm8, ymm13
  vmovapd yword [rsp+40], ymm6
  vmovapd yword [rsp+840], ymm1
  vmulpd ymm1, ymm8, ymm10
  vaddpd ymm1, ymm1, ymm4
  vmulpd ymm4, ymm6, ymm7
  vaddpd ymm2, ymm2, ymm0
  vmulpd ymm0, ymm8, ymm14
  vaddpd ymm5, ymm4, ymm5
  vmulpd ymm4, ymm6, ymm12
  vaddpd ymm4, ymm4, ymm1
  vmulpd ymm1, ymm6, ymm10
  vaddpd ymm3, ymm1, ymm3
  vmulpd ymm1, ymm6, ymm9
  vmovapd yword [rsp+808], ymm5
  vaddpd ymm2, ymm1, ymm2
  vmulpd ymm1, ymm6, ymm13
  vaddpd ymm1, ymm1, ymm0
  vmulpd ymm0, ymm6, ymm14
  vmovapd ymm6, yword [rsi+128]
  vmulpd ymm5, ymm6, ymm7
  vaddpd ymm4, ymm5, ymm4
  vmovapd ymm5, yword [rsi+160]
  vmovapd ymm15, ymm5
  vmulpd ymm5, ymm5, ymm7
  vmovapd yword [rsp-24], ymm4
  vmulpd ymm4, ymm6, ymm12
  vaddpd ymm3, ymm4, ymm3
  vmulpd ymm4, ymm6, ymm10
  vaddpd ymm2, ymm4, ymm2
  vmulpd ymm4, ymm6, ymm9
  vmulpd ymm7, ymm15, ymm9
  vmulpd ymm9, ymm15, ymm13
  vaddpd ymm1, ymm4, ymm1
  vmulpd ymm4, ymm6, ymm13
  vaddpd ymm3, ymm5, ymm3
  vmulpd ymm5, ymm15, ymm10
  vaddpd ymm0, ymm4, ymm0
  vmulpd ymm4, ymm6, ymm14
  vmovapd yword [rsp-56], ymm3
  vmulpd ymm3, ymm15, ymm12
  vaddpd ymm2, ymm3, ymm2
  vaddpd ymm3, ymm5, ymm1
  vaddpd ymm5, ymm7, ymm0
  vmovapd yword [rsp+776], ymm2
  vaddpd ymm1, ymm9, ymm4
  vmulpd ymm4, ymm15, ymm14
  vmovapd yword [rsp+744], ymm3
  vmovapd yword [rsp+712], ymm5
  vmovapd yword [rsp+136], ymm13
  vmovapd ymm5, yword [rel .LC0]
  vmovapd ymm3, yword [rel .LC1]
  vmovapd yword [rsp+8], ymm15
  vandpd ymm9, ymm3, yword [rsi+224]
  vandpd ymm7, ymm3, yword [rsi+288]
  vmovapd yword [rsp+104], ymm14
  vmovapd ymm0, yword [rel .LC0]
  vmulpd ymm2, ymm0, yword [rdx+192]
  vmulpd ymm15, ymm9, ymm2
  vandpd ymm0, ymm3, yword [rdx+256]
  vmovapd ymm13, yword [rel .LC0]
  vmovapd yword [rsp+680], ymm1
  vmulpd ymm1, ymm5, yword [rsi+192]
  vmovapd ymm10, ymm1
  vandpd ymm1, ymm3, yword [rsi+256]
  vmovapd yword [rsp+968], ymm1
  vandpd ymm1, ymm3, yword [rdx+224]
  vmulpd ymm14, ymm1, ymm10
  vaddpd ymm14, ymm15, ymm14
  vmulpd ymm11, ymm0, ymm10
  vmulpd ymm5, ymm5, yword [rsi+352]
  vmulpd ymm15, ymm9, ymm0
  vmovapd yword [rsp-88], ymm10
  vmovapd yword [rsp+616], ymm5
  vandpd ymm5, ymm3, yword [rdx+288]
  vmulpd ymm12, ymm5, ymm10
  vaddpd ymm12, ymm15, ymm12
  vmovapd yword [rsp+552], ymm14
  vmulpd ymm14, ymm9, ymm1
  vaddpd ymm11, ymm14, ymm11
  vmulpd ymm15, ymm2, yword [rsp+968]
  vmovapd yword [rsp+648], ymm4
  vmulpd ymm14, ymm9, ymm5
  vandpd ymm4, ymm3, yword [rsi+320]
  vandpd ymm3, ymm3, yword [rdx+320]
  vmovapd yword [rsp+936], ymm4
  vmulpd ymm4, ymm13, yword [rdx+352]
  vmulpd ymm13, ymm2, ymm10
  vmovapd yword [rsp+584], ymm13
  vaddpd ymm11, ymm15, ymm11
  vmulpd ymm13, ymm3, ymm10
  vmulpd ymm10, ymm4, ymm10
  vaddpd ymm14, ymm14, ymm13
  vmulpd ymm13, ymm9, ymm3
  vaddpd ymm13, ymm13, ymm10
  vmulpd ymm10, ymm9, ymm4
  vmovapd yword [rsp+520], ymm11
  vmovapd ymm11, yword [rsp+968]
  vmulpd ymm15, ymm1, ymm11
  vaddpd ymm15, ymm15, ymm12
  vmovapd ymm12, ymm11
  vmulpd ymm11, ymm0, ymm11
  vaddpd ymm11, ymm11, ymm14
  vmovapd ymm14, ymm12
  vmulpd ymm12, ymm5, ymm12
  vaddpd ymm13, ymm12, ymm13
  vmulpd ymm12, ymm3, ymm14
  vaddpd ymm12, ymm12, ymm10
  vmulpd ymm10, ymm4, ymm14
  vmulpd ymm14, ymm7, ymm2
  vaddpd ymm14, ymm14, ymm15
  vmulpd ymm15, ymm2, yword [rsp+936]
  vmovapd yword [rsp+488], ymm14
  vmulpd ymm14, ymm7, ymm1
  vaddpd ymm14, ymm14, ymm11
  vmulpd ymm11, ymm7, ymm0
  vaddpd ymm13, ymm11, ymm13
  vmulpd ymm11, ymm7, ymm5
  vaddpd ymm12, ymm11, ymm12
  vmulpd ymm11, ymm7, ymm3
  vaddpd ymm14, ymm15, ymm14
  vaddpd ymm11, ymm11, ymm10
  vmulpd ymm10, ymm7, ymm4
  vmovapd yword [rsp+456], ymm14
  vmovapd ymm15, yword [rsp+936]
  vsubpd ymm8, ymm8, yword [rsp+968]
  vsubpd ymm6, ymm6, yword [rsp+936]
  vmulpd ymm14, ymm1, ymm15
  vaddpd ymm13, ymm14, ymm13
  vmulpd ymm14, ymm0, ymm15
  vaddpd ymm12, ymm14, ymm12
  vmulpd ymm14, ymm5, ymm15
  vaddpd ymm11, ymm14, ymm11
  vmulpd ymm14, ymm3, ymm15
  vaddpd ymm10, ymm14, ymm10
  vmulpd ymm14, ymm4, ymm15
  vmulpd ymm15, ymm2, yword [rsp+616]
  vaddpd ymm13, ymm15, ymm13
  vmovapd ymm15, yword [rsp+616]
  vsubpd ymm2, ymm2, yword [rsp+264]
  vmovapd yword [rsp-120], ymm13
  vmulpd ymm13, ymm1, ymm15
  vaddpd ymm12, ymm13, ymm12
  vmovapd ymm13, ymm15
  vsubpd ymm1, ymm1, yword [rsp+232]
  vmovapd yword [rsp+616], ymm12
  vmulpd ymm12, ymm0, ymm15
  vaddpd ymm12, ymm12, ymm11
  vmulpd ymm11, ymm5, ymm15
  vaddpd ymm15, ymm11, ymm10
  vmovapd ymm11, yword [rsp+72]
  vmulpd ymm10, ymm3, ymm13
  vsubpd ymm0, ymm0, yword [rsp+200]
  vmovapd yword [rsp+424], ymm12
  vaddpd ymm12, ymm10, ymm14
  vmovapd yword [rsp+392], ymm15
  vsubpd ymm9, ymm11, ymm9
  vmovapd ymm11, yword [rsp+40]
  vmulpd ymm15, ymm4, ymm13
  vmovapd yword [rsp+328], ymm15
  vmovapd ymm15, yword [rsp+296]
  vmovapd yword [rsp+360], ymm12
  vsubpd ymm10, ymm15, yword [rsp-88]
  vsubpd ymm7, ymm11, ymm7
  vmovapd ymm11, yword [rsp+8]
  vsubpd ymm12, ymm5, yword [rsp+168]
  vsubpd ymm14, ymm11, ymm13
  vmulpd ymm5, ymm10, ymm1
  vmovapd ymm13, yword [rel .LC3]
  vsubpd ymm11, ymm3, yword [rsp+136]
  vmulpd ymm3, ymm10, ymm0
  vmovapd yword [rsp+296], ymm3
  vmulpd ymm3, ymm10, ymm2
  vmovapd yword [rsp+936], ymm12
  vsubpd ymm15, ymm4, yword [rsp+104]
  vmulpd ymm4, ymm10, ymm12
  vaddpd ymm3, ymm3, yword [rsp+904]
  vmovapd yword [rsp+264], ymm4
  vaddpd ymm3, ymm3, yword [rsp+584]
  vmulpd ymm12, ymm10, ymm11
  vmovapd yword [rsp+968], ymm11
  vmovapd ymm4, yword [rel .LC2]
  vmulpd ymm11, ymm10, ymm15
  vmulpd ymm10, ymm13, yword [rsp+616]
  vmulpd ymm3, ymm3, ymm4
  vaddpd ymm3, ymm3, yword [rsp+776]
  vaddpd ymm3, ymm3, ymm10
  vmovapd yword [rdi+192], ymm3
  vmulpd ymm3, ymm9, ymm1
  vaddpd ymm3, ymm3, yword [rsp+296]
  vmovapd yword [rsp+296], ymm3
  vmulpd ymm3, ymm9, ymm0
  vaddpd ymm10, ymm3, yword [rsp+264]
  vmulpd ymm3, ymm9, yword [rsp+936]
  vaddpd ymm12, ymm3, ymm12
  vmulpd ymm3, ymm9, yword [rsp+968]
  vaddpd ymm11, ymm3, ymm11
  vmulpd ymm3, ymm9, ymm15
  vmulpd ymm9, ymm9, ymm2
  vaddpd ymm5, ymm9, ymm5
  vmulpd ymm9, ymm13, yword [rsp+424]
  vaddpd ymm5, ymm5, yword [rsp+872]
  vaddpd ymm5, ymm5, yword [rsp+552]
  vmulpd ymm5, ymm5, ymm4
  vaddpd ymm5, ymm5, yword [rsp+744]
  vaddpd ymm5, ymm5, ymm9
  vmulpd ymm9, ymm13, yword [rsp+392]
  vmovapd yword [rdi+224], ymm5
  vmulpd ymm5, ymm8, ymm1
  vaddpd ymm10, ymm5, ymm10
  vmulpd ymm5, ymm8, ymm0
  vaddpd ymm12, ymm5, ymm12
  vmulpd ymm5, ymm8, yword [rsp+936]
  vaddpd ymm11, ymm5, ymm11
  vmulpd ymm5, ymm8, yword [rsp+968]
  vaddpd ymm3, ymm5, ymm3
  vmulpd ymm5, ymm8, ymm15
  vmulpd ymm8, ymm8, ymm2
  vaddpd ymm8, ymm8, yword [rsp+296]
  vaddpd ymm8, ymm8, yword [rsp+840]
  vaddpd ymm8, ymm8, yword [rsp+520]
  vmulpd ymm8, ymm8, ymm4
  vaddpd ymm8, ymm8, yword [rsp+712]
  vaddpd ymm8, ymm8, ymm9
  vmulpd ymm9, ymm13, yword [rsp+360]
  vmovapd yword [rdi+256], ymm8
  vmulpd ymm8, ymm7, ymm1
  vaddpd ymm12, ymm8, ymm12
  vmulpd ymm8, ymm7, ymm0
  vaddpd ymm11, ymm8, ymm11
  vmulpd ymm8, ymm7, yword [rsp+936]
  vaddpd ymm3, ymm8, ymm3
  vmulpd ymm8, ymm7, yword [rsp+968]
  vaddpd ymm5, ymm8, ymm5
  vmulpd ymm8, ymm7, ymm15
  vmulpd ymm7, ymm7, ymm2
  vaddpd ymm7, ymm7, ymm10
  vmovapd ymm10, yword [rsp+936]
  vaddpd ymm7, ymm7, yword [rsp+808]
  vaddpd ymm7, ymm7, yword [rsp+488]
  vmulpd ymm7, ymm7, ymm4
  vaddpd ymm7, ymm7, yword [rsp+680]
  vaddpd ymm7, ymm7, ymm9
  vmulpd ymm9, ymm6, ymm15
  vmovapd yword [rdi+288], ymm7
  vmulpd ymm7, ymm6, ymm1
  vaddpd ymm11, ymm7, ymm11
  vmulpd ymm7, ymm6, ymm0
  vaddpd ymm3, ymm7, ymm3
  vmulpd ymm7, ymm6, ymm10
  vmulpd ymm0, ymm14, ymm0
  vmulpd ymm1, ymm14, ymm1
  vaddpd ymm5, ymm7, ymm5
  vmulpd ymm7, ymm6, yword [rsp+968]
  vmulpd ymm6, ymm6, ymm2
  vmulpd ymm2, ymm14, ymm2
  vaddpd ymm6, ymm6, ymm12
  vmovapd ymm12, yword [rsp-24]
  vaddpd ymm8, ymm7, ymm8
  vmulpd ymm7, ymm13, yword [rsp+328]
  vaddpd ymm11, ymm2, ymm11
  vaddpd ymm6, ymm6, ymm12
  vaddpd ymm6, ymm6, yword [rsp+456]
  vaddpd ymm5, ymm0, ymm5
  vaddpd ymm3, ymm1, ymm3
  vmulpd ymm6, ymm6, ymm4
  vaddpd ymm6, ymm6, yword [rsp+648]
  vaddpd ymm6, ymm6, ymm7
  vmovapd yword [rdi+320], ymm6
  vmovapd ymm7, yword [rsp-56]
  vaddpd ymm5, ymm5, yword [rsp+744]
  vaddpd ymm11, ymm11, ymm7
  vmovapd ymm2, yword [rsp-120]
  vaddpd ymm5, ymm5, yword [rsp+424]
  vmulpd ymm5, ymm5, yword [rel .LC0]
  vaddpd ymm5, ymm5, yword [rsp+552]
  vaddpd ymm11, ymm11, ymm2
  vaddpd ymm3, ymm3, yword [rsp+776]
  vaddpd ymm1, ymm3, yword [rsp+616]
  vmulpd ymm5, ymm5, ymm13
  vmulpd ymm1, ymm1, yword [rel .LC0]
  vaddpd ymm5, ymm5, yword [rsp+872]
  vmulpd ymm4, ymm11, ymm4
  vmovapd yword [rdi+352], ymm4
  vmulpd ymm4, ymm14, ymm15
  vaddpd ymm1, ymm1, yword [rsp+584]
  vaddpd ymm4, ymm4, yword [rsp+648]
  vaddpd ymm4, ymm4, yword [rsp+328]
  vmovapd yword [rdi+32], ymm5
  vmulpd ymm4, ymm4, yword [rel .LC0]
  vmulpd ymm5, ymm14, ymm10
  vaddpd ymm4, ymm4, yword [rsp+456]
  vmulpd ymm1, ymm1, ymm13
  vaddpd ymm8, ymm5, ymm8
  vmulpd ymm5, ymm14, yword [rsp+968]
  vaddpd ymm8, ymm8, yword [rsp+712]
  vaddpd ymm5, ymm5, ymm9
  vmulpd ymm4, ymm4, ymm13
  vaddpd ymm8, ymm8, yword [rsp+392]
  vmulpd ymm8, ymm8, yword [rel .LC0]
  vaddpd ymm5, ymm5, yword [rsp+680]
  vaddpd ymm6, ymm8, yword [rsp+520]
  vaddpd ymm5, ymm5, yword [rsp+360]
  vmulpd ymm5, ymm5, yword [rel .LC0]
  vaddpd ymm5, ymm5, yword [rsp+488]
  vaddpd ymm1, ymm1, yword [rsp+904]
  vmulpd ymm6, ymm6, ymm13
  vaddpd ymm4, ymm4, ymm12
  vaddpd ymm6, ymm6, yword [rsp+840]
  vmulpd ymm5, ymm5, ymm13
  vmulpd ymm13, ymm13, ymm2
  vaddpd ymm5, ymm5, yword [rsp+808]
  vmovapd yword [rdi], ymm1
  vaddpd ymm3, ymm13, ymm7
  vmovapd yword [rdi+64], ymm6
  vmovapd yword [rdi+96], ymm5
  vmovapd yword [rdi+128], ymm4
  vmovapd yword [rdi+160], ymm3
  leave
  bench_epilogue
  ret

section .rodata

align 32, db 0
.LC0:
  dq 0
  dq 938475520
  dq 0
  dq 938475520
  dq 0
  dq 938475520
  dq 0
  dq 938475520
.LC1:
  dq 4294967295
  dq -134217729
  dq 4294967295
  dq -134217729
  dq 4294967295
  dq -134217729
  dq 4294967295
  dq -134217729
.LC2:
  dq 0
  dq 1206910976
  dq 0
  dq 1206910976
  dq 0
  dq 1206910976
  dq 0
  dq 1206910976
.LC3:
  dq 0
  dq 1078132736
  dq 0
  dq 1078132736
  dq 0
  dq 1078132736
  dq 0
  dq 1078132736


section .text

fe12_mul_clang: ; @fe12_mul
    lea rdi, [rel scratch_space]
    lea rsi, [rel scratch_space+384]
    bench_prologue
    lea rdx, [rel scratch_space+768]
    sub rsp, 888
    vmovapd ymm9, yword [rdx]
    vmovapd ymm1, yword [rdx + 32]
    vmovapd ymm7, yword [rdx + 64]
    vmovapd ymm8, yword [rdx + 96]
    vmovapd ymm6, yword [rsi]
    vmovupd yword [rsp], ymm6 ; 32-byte Spill
    vmovapd ymm12, yword [rsi + 32]
    vmovapd ymm13, yword [rsi + 64]
    vmulpd ymm0, ymm6, ymm1
    vmulpd ymm2, ymm6, ymm7
    vmulpd ymm3, ymm6, ymm8
    vmovapd ymm5, yword [rdx + 128]
    vmulpd ymm4, ymm6, ymm5
    vmovapd ymm11, ymm5
    vmovapd ymm10, yword [rdx + 160]
    vmulpd ymm5, ymm6, ymm10
    vmovapd ymm14, ymm10
    vmovupd yword [rsp - 32], ymm12 ; 32-byte Spill
    vmulpd ymm6, ymm9, ymm12
    vaddpd ymm0, ymm0, ymm6
    vmovupd yword [rsp + 832], ymm0 ; 32-byte Spill
    vmulpd ymm0, ymm1, ymm12
    vaddpd ymm0, ymm2, ymm0
    vmulpd ymm2, ymm7, ymm12
    vaddpd ymm2, ymm3, ymm2
    vmulpd ymm3, ymm8, ymm12
    vaddpd ymm3, ymm4, ymm3
    vmulpd ymm4, ymm11, ymm12
    vaddpd ymm4, ymm5, ymm4
    vmulpd ymm5, ymm10, ymm12
    vmulpd ymm6, ymm9, ymm13
    vaddpd ymm0, ymm0, ymm6
    vmovupd yword [rsp + 800], ymm0 ; 32-byte Spill
    vmulpd ymm0, ymm1, ymm13
    vaddpd ymm0, ymm2, ymm0
    vmulpd ymm2, ymm7, ymm13
    vaddpd ymm2, ymm3, ymm2
    vmulpd ymm3, ymm8, ymm13
    vaddpd ymm3, ymm4, ymm3
    vmulpd ymm4, ymm11, ymm13
    vmovupd yword [rsp + 160], ymm13 ; 32-byte Spill
    vaddpd ymm4, ymm5, ymm4
    vmovapd ymm6, yword [rsi + 96]
    vmulpd ymm5, ymm9, ymm6
    vaddpd ymm0, ymm0, ymm5
    vmovupd yword [rsp + 768], ymm0 ; 32-byte Spill
    vmulpd ymm0, ymm1, ymm6
    vaddpd ymm0, ymm2, ymm0
    vmulpd ymm2, ymm7, ymm6
    vaddpd ymm2, ymm3, ymm2
    vmulpd ymm3, ymm8, ymm6
    vmovapd ymm10, ymm8
    vaddpd ymm3, ymm4, ymm3
    vmulpd ymm4, ymm14, ymm13
    vmulpd ymm5, ymm11, ymm6
    vmovapd ymm12, ymm6
    vmovupd yword [rsp - 64], ymm6 ; 32-byte Spill
    vaddpd ymm4, ymm4, ymm5
    vmovapd ymm8, yword [rsi + 128]
    vmovupd yword [rsp + 96], ymm9 ; 32-byte Spill
    vmulpd ymm5, ymm9, ymm8
    vaddpd ymm0, ymm0, ymm5
    vmovupd yword [rsp + 736], ymm0 ; 32-byte Spill
    vmovupd yword [rsp + 128], ymm1 ; 32-byte Spill
    vmulpd ymm0, ymm1, ymm8
    vaddpd ymm0, ymm2, ymm0
    vmovupd yword [rsp + 64], ymm7 ; 32-byte Spill
    vmulpd ymm2, ymm7, ymm8
    vaddpd ymm2, ymm3, ymm2
    vmovapd ymm6, ymm10
    vmovupd yword [rsp + 512], ymm10 ; 32-byte Spill
    vmulpd ymm3, ymm10, ymm8
    vaddpd ymm3, ymm4, ymm3
    vmulpd ymm4, ymm14, ymm12
    vmovupd yword [rsp + 480], ymm14 ; 32-byte Spill
    vmulpd ymm5, ymm11, ymm8
    vmovupd yword [rsp + 448], ymm11 ; 32-byte Spill
    vaddpd ymm4, ymm4, ymm5
    vmovapd ymm10, yword [rsi + 160]
    vmulpd ymm5, ymm9, ymm10
    vaddpd ymm0, ymm0, ymm5
    vmovupd yword [rsp + 704], ymm0 ; 32-byte Spill
    vmulpd ymm0, ymm1, ymm10
    vaddpd ymm0, ymm2, ymm0
    vmovupd yword [rsp + 288], ymm0 ; 32-byte Spill
    vmulpd ymm0, ymm7, ymm10
    vaddpd ymm0, ymm3, ymm0
    vmovupd yword [rsp + 672], ymm0 ; 32-byte Spill
    vmulpd ymm0, ymm6, ymm10
    vmovupd yword [rsp + 416], ymm10 ; 32-byte Spill
    vaddpd ymm0, ymm4, ymm0
    vmovupd yword [rsp + 320], ymm0 ; 32-byte Spill
    vmulpd ymm0, ymm14, ymm8
    vmovapd ymm1, yword [rel .LCPI0_0] ; ymm1 = [2.938736e-39,2.938736e-39,2.938736e-39,2.938736e-39]
    vmulpd ymm9, ymm1, yword [rsi + 192]
    vmulpd ymm2, ymm11, ymm10
    vmovapd ymm11, yword [rel .LCPI0_1] ; ymm11 = [17870283321406128127,17870283321406128127,17870283321406128127,17870283321406128127]
    vandpd ymm15, ymm11, yword [rsi + 224]
    vmulpd ymm10, ymm1, yword [rdx + 192]
    vmovapd ymm7, ymm1
    vandpd ymm12, ymm11, yword [rdx + 224]
    vaddpd ymm0, ymm0, ymm2
    vmovupd yword [rsp + 256], ymm0 ; 32-byte Spill
    vmulpd ymm0, ymm9, ymm12
    vmulpd ymm2, ymm10, ymm15
    vaddpd ymm0, ymm2, ymm0
    vmovupd yword [rsp + 640], ymm0 ; 32-byte Spill
    vandpd ymm6, ymm11, yword [rdx + 256]
    vmulpd ymm0, ymm9, ymm6
    vmulpd ymm2, ymm15, ymm12
    vaddpd ymm0, ymm2, ymm0
    vmovupd yword [rsp - 128], ymm0 ; 32-byte Spill
    vandpd ymm5, ymm11, yword [rdx + 288]
    vmulpd ymm2, ymm9, ymm5
    vmulpd ymm4, ymm15, ymm6
    vaddpd ymm1, ymm4, ymm2
    vandpd ymm3, ymm11, yword [rdx + 320]
    vmulpd ymm4, ymm7, yword [rdx + 352]
    vmulpd ymm7, ymm9, ymm3
    vmulpd ymm14, ymm15, ymm5
    vaddpd ymm14, ymm14, ymm7
    vmulpd ymm7, ymm9, ymm4
    vmulpd ymm13, ymm15, ymm3
    vaddpd ymm13, ymm7, ymm13
    vandpd ymm7, ymm11, yword [rsi + 256]
    vmulpd ymm0, ymm10, ymm7
    vaddpd ymm0, ymm0, yword [rsp - 128] ; 32-byte Folded Reload
    vmovupd yword [rsp + 608], ymm0 ; 32-byte Spill
    vmulpd ymm0, ymm7, ymm12
    vaddpd ymm0, ymm0, ymm1
    vmovupd yword [rsp - 128], ymm0 ; 32-byte Spill
    vmulpd ymm0, ymm7, ymm6
    vaddpd ymm14, ymm0, ymm14
    vmulpd ymm0, ymm7, ymm5
    vaddpd ymm13, ymm0, ymm13
    vmulpd ymm0, ymm4, ymm15
    vmulpd ymm1, ymm7, ymm3
    vaddpd ymm0, ymm0, ymm1
    vmovupd yword [rsp - 96], ymm0 ; 32-byte Spill
    vandpd ymm2, ymm11, yword [rsi + 288]
    vmulpd ymm1, ymm10, ymm2
    vaddpd ymm0, ymm1, yword [rsp - 128] ; 32-byte Folded Reload
    vmovupd yword [rsp + 576], ymm0 ; 32-byte Spill
    vmulpd ymm1, ymm2, ymm12
    vaddpd ymm0, ymm1, ymm14
    vmulpd ymm14, ymm2, ymm6
    vaddpd ymm1, ymm14, ymm13
    vmovupd yword [rsp - 128], ymm1 ; 32-byte Spill
    vmulpd ymm14, ymm2, ymm5
    vaddpd ymm14, ymm14, yword [rsp - 96] ; 32-byte Folded Reload
    vmulpd ymm1, ymm4, ymm7
    vmulpd ymm13, ymm2, ymm3
    vaddpd ymm1, ymm1, ymm13
    vmovupd yword [rsp - 96], ymm1 ; 32-byte Spill
    vandpd ymm11, ymm11, yword [rsi + 320]
    vmulpd ymm13, ymm10, ymm11
    vaddpd ymm0, ymm13, ymm0
    vmovupd yword [rsp + 544], ymm0 ; 32-byte Spill
    vmulpd ymm13, ymm11, ymm12
    vaddpd ymm0, ymm13, yword [rsp - 128] ; 32-byte Folded Reload
    vmovupd yword [rsp - 128], ymm0 ; 32-byte Spill
    vmulpd ymm1, ymm11, ymm6
    vaddpd ymm0, ymm1, ymm14
    vmovupd yword [rsp + 32], ymm0 ; 32-byte Spill
    vmulpd ymm14, ymm11, ymm5
    vaddpd ymm14, ymm14, yword [rsp - 96] ; 32-byte Folded Reload
    vmovapd ymm0, yword [rel .LCPI0_0] ; ymm0 = [2.938736e-39,2.938736e-39,2.938736e-39,2.938736e-39]
    vmulpd ymm0, ymm0, yword [rsi + 352]
    vmulpd ymm1, ymm4, ymm2
    vmulpd ymm13, ymm11, ymm3
    vaddpd ymm1, ymm1, ymm13
    vmulpd ymm13, ymm0, ymm10
    vaddpd ymm13, ymm13, yword [rsp - 128] ; 32-byte Folded Reload
    vmovupd yword [rsp - 128], ymm13 ; 32-byte Spill
    vmulpd ymm13, ymm0, ymm12
    vaddpd ymm13, ymm13, yword [rsp + 32] ; 32-byte Folded Reload
    vmovupd yword [rsp + 192], ymm13 ; 32-byte Spill
    vmulpd ymm13, ymm0, ymm6
    vaddpd ymm13, ymm13, ymm14
    vmovupd yword [rsp + 224], ymm13 ; 32-byte Spill
    vmulpd ymm13, ymm0, ymm5
    vaddpd ymm1, ymm13, ymm1
    vmovupd yword [rsp + 32], ymm1 ; 32-byte Spill
    vmulpd ymm1, ymm4, ymm11
    vmulpd ymm13, ymm0, ymm3
    vaddpd ymm1, ymm1, ymm13
    vmovupd yword [rsp - 96], ymm1 ; 32-byte Spill
    vmovupd ymm1, yword [rsp - 32] ; 32-byte Reload
    vsubpd ymm1, ymm1, ymm15
    vmovupd ymm13, yword [rsp + 160] ; 32-byte Reload
    vsubpd ymm14, ymm13, ymm7
    vmovupd ymm7, yword [rsp - 64] ; 32-byte Reload
    vsubpd ymm7, ymm7, ymm2
    vsubpd ymm11, ymm8, ymm11
    vmovupd ymm2, yword [rsp + 96] ; 32-byte Reload
    vmovupd ymm8, yword [rsp] ; 32-byte Reload
    vmulpd ymm13, ymm8, ymm2
    vmovupd yword [rsp + 384], ymm13 ; 32-byte Spill
    vsubpd ymm8, ymm8, ymm9
    vmulpd ymm9, ymm9, ymm10
    vmovupd yword [rsp + 352], ymm9 ; 32-byte Spill
    vsubpd ymm15, ymm10, ymm2
    vsubpd ymm12, ymm12, yword [rsp + 128] ; 32-byte Folded Reload
    vsubpd ymm6, ymm6, yword [rsp + 64] ; 32-byte Folded Reload
    vsubpd ymm5, ymm5, yword [rsp + 512] ; 32-byte Folded Reload
    vsubpd ymm2, ymm3, yword [rsp + 448] ; 32-byte Folded Reload
    vmovupd ymm3, yword [rsp + 480] ; 32-byte Reload
    vmovupd ymm10, yword [rsp + 416] ; 32-byte Reload
    vmulpd ymm9, ymm3, ymm10
    vmovupd yword [rsp], ymm9 ; 32-byte Spill
    vsubpd ymm9, ymm10, ymm0
    vmulpd ymm0, ymm0, ymm4
    vmovupd yword [rsp - 32], ymm0 ; 32-byte Spill
    vsubpd ymm4, ymm4, ymm3
    vmulpd ymm0, ymm8, ymm12
    vmulpd ymm10, ymm1, ymm15
    vaddpd ymm0, ymm10, ymm0
    vmovupd yword [rsp + 160], ymm0 ; 32-byte Spill
    vmulpd ymm0, ymm8, ymm6
    vmulpd ymm10, ymm1, ymm12
    vaddpd ymm0, ymm10, ymm0
    vmovupd yword [rsp - 64], ymm0 ; 32-byte Spill
    vmulpd ymm10, ymm8, ymm5
    vmulpd ymm3, ymm1, ymm6
    vaddpd ymm3, ymm3, ymm10
    vmulpd ymm10, ymm8, ymm2
    vmulpd ymm13, ymm1, ymm5
    vaddpd ymm10, ymm13, ymm10
    vmulpd ymm13, ymm8, ymm4
    vmulpd ymm0, ymm1, ymm2
    vaddpd ymm0, ymm13, ymm0
    vmulpd ymm13, ymm14, ymm15
    vaddpd ymm13, ymm13, yword [rsp - 64] ; 32-byte Folded Reload
    vmovupd yword [rsp - 64], ymm13 ; 32-byte Spill
    vmulpd ymm13, ymm14, ymm12
    vaddpd ymm3, ymm13, ymm3
    vmulpd ymm13, ymm14, ymm6
    vaddpd ymm10, ymm13, ymm10
    vmulpd ymm13, ymm14, ymm5
    vaddpd ymm0, ymm13, ymm0
    vmulpd ymm1, ymm1, ymm4
    vmulpd ymm13, ymm14, ymm2
    vaddpd ymm1, ymm1, ymm13
    vmulpd ymm13, ymm7, ymm15
    vaddpd ymm3, ymm13, ymm3
    vmovupd yword [rsp + 128], ymm3 ; 32-byte Spill
    vmulpd ymm3, ymm7, ymm12
    vaddpd ymm3, ymm3, ymm10
    vmulpd ymm10, ymm7, ymm6
    vaddpd ymm0, ymm10, ymm0
    vmulpd ymm10, ymm7, ymm5
    vaddpd ymm1, ymm10, ymm1
    vmulpd ymm10, ymm14, ymm4
    vmulpd ymm13, ymm7, ymm2
    vaddpd ymm10, ymm10, ymm13
    vmulpd ymm13, ymm11, ymm15
    vaddpd ymm3, ymm13, ymm3
    vmovupd yword [rsp + 96], ymm3 ; 32-byte Spill
    vmulpd ymm3, ymm11, ymm12
    vaddpd ymm0, ymm3, ymm0
    vmulpd ymm3, ymm11, ymm6
    vaddpd ymm3, ymm3, ymm1
    vmulpd ymm1, ymm11, ymm5
    vaddpd ymm10, ymm1, ymm10
    vmulpd ymm1, ymm7, ymm4
    vmulpd ymm7, ymm11, ymm2
    vaddpd ymm7, ymm1, ymm7
    vmulpd ymm1, ymm8, ymm15
    vmulpd ymm8, ymm9, ymm15
    vaddpd ymm0, ymm8, ymm0
    vmovupd yword [rsp + 64], ymm0 ; 32-byte Spill
    vmulpd ymm8, ymm9, ymm12
    vaddpd ymm3, ymm8, ymm3
    vmulpd ymm6, ymm9, ymm6
    vaddpd ymm6, ymm6, ymm10
    vmulpd ymm5, ymm9, ymm5
    vaddpd ymm5, ymm5, ymm7
    vmulpd ymm7, ymm11, ymm4
    vmulpd ymm2, ymm9, ymm2
    vaddpd ymm2, ymm7, ymm2
    vmulpd ymm4, ymm9, ymm4
    vaddpd ymm3, ymm3, yword [rsp + 288] ; 32-byte Folded Reload
    vaddpd ymm3, ymm3, yword [rsp + 192] ; 32-byte Folded Reload
    vmovapd ymm7, yword [rel .LCPI0_0] ; ymm7 = [2.938736e-39,2.938736e-39,2.938736e-39,2.938736e-39]
    vmulpd ymm3, ymm3, ymm7
    vmovupd ymm12, yword [rsp + 352] ; 32-byte Reload
    vaddpd ymm3, ymm12, ymm3
    vmovapd ymm9, yword [rel .LCPI0_2] ; ymm9 = [3.800000e+01,3.800000e+01,3.800000e+01,3.800000e+01]
    vmulpd ymm3, ymm3, ymm9
    vmovupd ymm0, yword [rsp + 384] ; 32-byte Reload
    vaddpd ymm3, ymm0, ymm3
    vmovapd yword [rdi], ymm3
    vmovupd ymm14, yword [rsp + 672] ; 32-byte Reload
    vaddpd ymm3, ymm14, ymm6
    vaddpd ymm3, ymm3, yword [rsp + 224] ; 32-byte Folded Reload
    vmulpd ymm3, ymm3, ymm7
    vmovupd ymm15, yword [rsp + 640] ; 32-byte Reload
    vaddpd ymm3, ymm15, ymm3
    vmulpd ymm3, ymm3, ymm9
    vmovupd ymm6, yword [rsp + 832] ; 32-byte Reload
    vaddpd ymm3, ymm6, ymm3
    vmovapd yword [rdi + 32], ymm3
    vaddpd ymm3, ymm5, yword [rsp + 320] ; 32-byte Folded Reload
    vaddpd ymm3, ymm3, yword [rsp + 32] ; 32-byte Folded Reload
    vmulpd ymm3, ymm3, ymm7
    vmovupd ymm11, yword [rsp + 608] ; 32-byte Reload
    vaddpd ymm3, ymm11, ymm3
    vmulpd ymm3, ymm3, ymm9
    vmovupd ymm5, yword [rsp + 800] ; 32-byte Reload
    vaddpd ymm3, ymm5, ymm3
    vmovapd yword [rdi + 64], ymm3
    vaddpd ymm2, ymm2, yword [rsp + 256] ; 32-byte Folded Reload
    vaddpd ymm2, ymm2, yword [rsp - 96] ; 32-byte Folded Reload
    vmulpd ymm2, ymm2, ymm7
    vmovapd ymm3, ymm7
    vmovupd ymm8, yword [rsp + 576] ; 32-byte Reload
    vaddpd ymm2, ymm8, ymm2
    vmulpd ymm2, ymm2, ymm9
    vmovupd ymm7, yword [rsp + 768] ; 32-byte Reload
    vaddpd ymm2, ymm7, ymm2
    vmovapd yword [rdi + 96], ymm2
    vaddpd ymm2, ymm4, yword [rsp] ; 32-byte Folded Reload
    vaddpd ymm2, ymm2, yword [rsp - 32] ; 32-byte Folded Reload
    vmulpd ymm2, ymm2, ymm3
    vmovupd ymm10, yword [rsp + 544] ; 32-byte Reload
    vaddpd ymm2, ymm2, ymm10
    vmulpd ymm2, ymm2, ymm9
    vmovupd ymm4, yword [rsp + 736] ; 32-byte Reload
    vaddpd ymm2, ymm4, ymm2
    vmovapd yword [rdi + 128], ymm2
    vmulpd ymm2, ymm9, yword [rsp - 128] ; 32-byte Folded Reload
    vmovupd ymm13, yword [rsp + 704] ; 32-byte Reload
    vaddpd ymm2, ymm13, ymm2
    vmovapd yword [rdi + 160], ymm2
    vaddpd ymm1, ymm0, ymm1
    vaddpd ymm2, ymm12, ymm1
    vmovapd ymm1, yword [rel .LCPI0_3] ; ymm1 = [3.402824e+38,3.402824e+38,3.402824e+38,3.402824e+38]
    vmulpd ymm2, ymm2, ymm1
    vaddpd ymm2, ymm2, yword [rsp + 288] ; 32-byte Folded Reload
    vmulpd ymm3, ymm9, yword [rsp + 192] ; 32-byte Folded Reload
    vaddpd ymm2, ymm2, ymm3
    vmovapd yword [rdi + 192], ymm2
    vaddpd ymm2, ymm6, yword [rsp + 160] ; 32-byte Folded Reload
    vaddpd ymm2, ymm15, ymm2
    vmulpd ymm2, ymm2, ymm1
    vaddpd ymm2, ymm14, ymm2
    vmulpd ymm3, ymm9, yword [rsp + 224] ; 32-byte Folded Reload
    vaddpd ymm2, ymm2, ymm3
    vmovapd yword [rdi + 224], ymm2
    vaddpd ymm2, ymm5, yword [rsp - 64] ; 32-byte Folded Reload
    vaddpd ymm2, ymm11, ymm2
    vmulpd ymm2, ymm2, ymm1
    vaddpd ymm2, ymm2, yword [rsp + 320] ; 32-byte Folded Reload
    vmulpd ymm3, ymm9, yword [rsp + 32] ; 32-byte Folded Reload
    vaddpd ymm2, ymm3, ymm2
    vmovapd yword [rdi + 256], ymm2
    vaddpd ymm2, ymm7, yword [rsp + 128] ; 32-byte Folded Reload
    vaddpd ymm2, ymm8, ymm2
    vmulpd ymm2, ymm2, ymm1
    vaddpd ymm2, ymm2, yword [rsp + 256] ; 32-byte Folded Reload
    vmulpd ymm3, ymm9, yword [rsp - 96] ; 32-byte Folded Reload
    vaddpd ymm2, ymm3, ymm2
    vmovapd yword [rdi + 288], ymm2
    vaddpd ymm2, ymm4, yword [rsp + 96] ; 32-byte Folded Reload
    vaddpd ymm2, ymm10, ymm2
    vmulpd ymm2, ymm2, ymm1
    vaddpd ymm2, ymm2, yword [rsp] ; 32-byte Folded Reload
    vmulpd ymm3, ymm9, yword [rsp - 32] ; 32-byte Folded Reload
    vaddpd ymm2, ymm3, ymm2
    vmovapd yword [rdi + 320], ymm2
    vaddpd ymm0, ymm13, yword [rsp + 64] ; 32-byte Folded Reload
    vaddpd ymm0, ymm0, yword [rsp - 128] ; 32-byte Folded Reload
    vmulpd ymm0, ymm0, ymm1
    vmovapd yword [rdi + 352], ymm0
    add rsp, 888
    bench_epilogue
    ; vzeroupper
    ret

section .rodata

.LCPI0_0:
dq 4030721666496593920 ; double 2.9387358770557188E-39
dq 4030721666496593920 ; double 2.9387358770557188E-39
dq 4030721666496593920 ; double 2.9387358770557188E-39
dq 4030721666496593920 ; double 2.9387358770557188E-39
.LCPI0_1:
dq -576460752303423489 ; 0xf7ffffffffffffff
dq -576460752303423489 ; 0xf7ffffffffffffff
dq -576460752303423489 ; 0xf7ffffffffffffff
dq -576460752303423489 ; 0xf7ffffffffffffff
.LCPI0_2:
dq 4630544841867001856 ; double 38
dq 4630544841867001856 ; double 38
dq 4630544841867001856 ; double 38
dq 4630544841867001856 ; double 38
.LCPI0_3:
dq 5183643171103440896 ; double 3.4028236692093846E+38
dq 5183643171103440896 ; double 3.4028236692093846E+38
dq 5183643171103440896 ; double 3.4028236692093846E+38
dq 5183643171103440896 ; double 3.4028236692093846E+38

section .text

fe12_mul_sandy2x:
    bench_prologue
    push rbp
    mov rbp, rsp
    and rsp, -32
    sub rsp, 1280

    vpunpckhqdq xmm1, xmm11, [rel scratch_space + 0*16]           ; qhasm: f1 = unpack_high(f0, r)
    vpunpcklqdq xmm0, xmm11, [rel scratch_space + 0*16]           ; qhasm: f0 = unpack_low(f0, r)
    vpmuludq xmm11, xmm0, xmm10             ; qhasm: 2x h0 = g0 * f0
    vpmuludq xmm13, xmm1, xmm10             ; qhasm: 2x h1 = g0 * f1
    movdqa  oword [rsp + 128], xmm1         ; qhasm: f1_stack = f1
    paddq xmm1, xmm1                        ; qhasm: 2x f1 += f1
    vpmuludq xmm14, xmm0, xmm12             ; qhasm: 2x r = g1 * f0
    movdqa  oword [rsp + 144], xmm0         ; qhasm: f0_stack = f0
    paddq xmm13, xmm14                      ; qhasm: 2x h1 += r
    vpmuludq xmm0, xmm1, xmm12              ; qhasm: 2x h2 = g1 * f1
    movdqa  oword [rsp + 448], xmm1         ; qhasm: f1_2_stack = f1
    vpunpckhqdq xmm3, xmm1, [rel scratch_space + 1*16]            ; qhasm: f3 = unpack_high(f2, r)
    vpunpcklqdq xmm1, xmm1, [rel scratch_space + 1*16]            ; qhasm: f2 = unpack_low(f2, r)
    vpmuludq xmm2, xmm1, xmm10              ; qhasm: 2x r = g0 * f2
    paddq xmm0, xmm2                        ; qhasm: 2x h2 += r
    vpmuludq xmm2, xmm3, xmm10              ; qhasm: 2x h3 = g0 * f3
    movdqa  oword [rsp + 464], xmm3         ; qhasm: f3_stack = f3
    paddq xmm3, xmm3                        ; qhasm: 2x f3 += f3
    vpmuludq xmm14, xmm1, xmm12             ; qhasm: 2x r = g1 * f2
    movdqa  oword [rsp + 480], xmm1         ; qhasm: f2_stack = f2
    paddq xmm2, xmm14                       ; qhasm: 2x h3 += r
    vpmuludq xmm1, xmm3, xmm12              ; qhasm: 2x h4 = g1 * f3
    movdqa  oword [rsp + 496], xmm3         ; qhasm: f3_2_stack = f3
    vpunpckhqdq xmm5, xmm3, [rel scratch_space + 2*16]            ; qhasm: f5 = unpack_high(f4, r)
    vpunpcklqdq xmm3, xmm3, [rel scratch_space + 2*16]            ; qhasm: f4 = unpack_low(f4, r)
    vpmuludq xmm4, xmm3, xmm10              ; qhasm: 2x r = g0 * f4
    paddq xmm1, xmm4                        ; qhasm: 2x h4 += r
    vpmuludq xmm4, xmm5, xmm10              ; qhasm: 2x h5 = g0 * f5
    movdqa  oword [rsp + 512], xmm5         ; qhasm: f5_stack = f5
    paddq xmm5, xmm5                        ; qhasm: 2x f5 += f5
    vpmuludq xmm14, xmm3, xmm12             ; qhasm: 2x r = g1 * f4
    movdqa  oword [rsp + 528], xmm3         ; qhasm: f4_stack = f4
    paddq xmm4, xmm14                       ; qhasm: 2x h5 += r
    vpunpckhqdq xmm7, xmm3, [rel scratch_space + 3*16]            ; qhasm: f7 = unpack_high(f6, r)
    vpunpcklqdq xmm3, xmm3, [rel scratch_space + 3*16]            ; qhasm: f6 = unpack_low(f6, r)
    vpmuludq xmm6, xmm3, xmm10              ; qhasm: 2x h6 = g0 * f6
    vpmuludq xmm14, xmm5, xmm12             ; qhasm: 2x r = g1 * f5
    movdqa  oword [rsp + 544], xmm5         ; qhasm: f5_2_stack = f5
    pmuludq xmm5, [rel .v19_19]              ; qhasm: 2x f5 *= mem128[ .v19_19 ]
    movdqa  oword [rsp + 560], xmm5         ; qhasm: f5_38_stack = f5
    paddq xmm6, xmm14                       ; qhasm: 2x h6 += r
    vpmuludq xmm5, xmm7, xmm10              ; qhasm: 2x h7 = g0 * f7
    movdqa  oword [rsp + 576], xmm7         ; qhasm: f7_stack = f7
    paddq xmm7, xmm7                        ; qhasm: 2x f7 += f7
    vpmuludq xmm14, xmm3, xmm12             ; qhasm: 2x r = g1 * f6
    movdqa  oword [rsp + 592], xmm3         ; qhasm: f6_stack = f6
    paddq xmm5, xmm14                       ; qhasm: 2x h7 += r
    pmuludq xmm3, [rel .v19_19]              ; qhasm: 2x f6 *= mem128[ .v19_19 ]
    movdqa  oword [rsp + 608], xmm3         ; qhasm: f6_19_stack = f6
    vpunpckhqdq xmm9, xmm3, [rel scratch_space + 4*16]            ; qhasm: f9 = unpack_high(f8, r)
    vpunpcklqdq xmm3, xmm3, [rel scratch_space + 4*16]            ; qhasm: f8 = unpack_low(f8, r)
    movdqa  oword [rsp + 624], xmm3         ; qhasm: f8_stack = f8
    vpmuludq xmm8, xmm7, xmm12              ; qhasm: 2x h8 = g1 * f7
    movdqa  oword [rsp + 640], xmm7         ; qhasm: f7_2_stack = f7
    pmuludq xmm7, [rel .v19_19]              ; qhasm: 2x f7 *= mem128[ .v19_19 ]
    movdqa  oword [rsp + 656], xmm7         ; qhasm: f7_38_stack = f7
    vpmuludq xmm7, xmm3, xmm10              ; qhasm: 2x r = g0 * f8
    paddq xmm8, xmm7                        ; qhasm: 2x h8 += r
    vpmuludq xmm7, xmm9, xmm10              ; qhasm: 2x h9 = g0 * f9
    movdqa  oword [rsp + 672], xmm9         ; qhasm: f9_stack = f9
    paddq xmm9, xmm9                        ; qhasm: 2x f9 += f9
    vpmuludq xmm10, xmm3, xmm12             ; qhasm: 2x r = g1 * f8
    paddq xmm7, xmm10                       ; qhasm: 2x h9 += r
    pmuludq xmm3, [rel .v19_19]              ; qhasm: 2x f8 *= mem128[ .v19_19 ]
    movdqa  oword [rsp + 688], xmm3         ; qhasm: f8_19_stack = f8
    pmuludq xmm12, [rel .v19_19]             ; qhasm: 2x g1 *= mem128[ .v19_19 ]
    vpmuludq xmm3, xmm9, xmm12              ; qhasm: 2x r = g1 * f9
    movdqa  oword [rsp + 704], xmm9         ; qhasm: f9_2_stack = f9
    paddq xmm11, xmm3                       ; qhasm: 2x h0 += r
    movdqa xmm3, oword [rsp + 0]            ; qhasm: g2 = x3_2
    movdqa xmm9, oword [rsp + 16]           ; qhasm: g3 = z3_2
    vpunpckhqdq xmm9, xmm10, [rel scratch_space + 5*16]           ; qhasm: g3 = unpack_high(g2, r)
    vpunpcklqdq xmm3, xmm10, [rel scratch_space + 5*16]           ; qhasm: g2 = unpack_low(g2, r)
    vpmuludq xmm10, xmm3, oword [rsp + 144] ; qhasm: 2x r2 = g2 * f0_stack
    paddq xmm0, xmm10                       ; qhasm: 2x h2 += r2
    vpmuludq xmm10, xmm3, oword [rsp + 128] ; qhasm: 2x r2 = g2 * f1_stack
    paddq xmm2, xmm10                       ; qhasm: 2x h3 += r2
    vpmuludq xmm10, xmm3, oword [rsp + 480] ; qhasm: 2x r2 = g2 * f2_stack
    paddq xmm1, xmm10                      ; qhasm: 2x h4 += r2    vpmuludq xmm10, xmm3, oword [rsp + 464] ; qhasm: 2x r2 = g2 * f3_stack
    paddq xmm4, xmm10                       ; qhasm: 2x h5 += r2
    vpmuludq xmm10, xmm3, oword [rsp + 528] ; qhasm: 2x r2 = g2 * f4_stack
    paddq xmm6, xmm10                       ; qhasm: 2x h6 += r2
    vpmuludq xmm10, xmm3, oword [rsp + 512] ; qhasm: 2x r2 = g2 * f5_stack
    paddq xmm5, xmm10                       ; qhasm: 2x h7 += r2
    vpmuludq xmm10, xmm3, oword [rsp + 592] ; qhasm: 2x r2 = g2 * f6_stack
    paddq xmm8, xmm10                       ; qhasm: 2x h8 += r2
    vpmuludq xmm10, xmm3, oword [rsp + 576] ; qhasm: 2x r2 = g2 * f7_stak
    paddq xmm7, xmm10                       ; qhasm: 2x h9 += r2
    pmuludq xmm3, [rel .v19_19]              ; qhasm: 2x g2 *= mem128[ .v19_19 ]
    vpmuludq xmm10, xmm3, oword [rsp + 624] ; qhasm: 2x r2 = g2 * f8_stack
    paddq xmm11, xmm10                      ; qhasm: 2x h0 += r2
    pmuludq xmm3, oword [rsp + 672]         ; qhasm: 2x g2 *= f9_stack
    paddq xmm13, xmm3                       ; qhasm: 2x h1 += g2
    vpmuludq xmm3, xmm9,oword [rsp + 144]  ; qhasm: 2x r3 = g3 * f0_stak
    paddq xmm2, xmm3                        ; qhasm: 2x h3 += r3
    vpmuludq xmm3, xmm9, oword [rsp + 448]  ; qhasm: 2x r3 = g3 * f1_2_stack
    paddq xmm1, xmm3                        ; qhasm: 2x h4 += r3
    vpmuludq xmm3, xmm9, oword [rsp + 480]  ; qhasm: 2x r3 = g3 * f2_stack
    paddq xmm4, xmm3                        ; qhasm: 2x h5 += r3
    vpmuludq xmm3, xmm9, oword [rsp + 496]  ; qhasm: 2x r3 = g3 * f3_2_stack
    paddq xmm6, xmm3                        ; qhasm: 2x h6 += r3
    vpmuludq xmm3, xmm9, oword [rsp + 528]  ; qhasm: 2x r3 = g3 * f4_stack
    paddq xmm5, xmm3                       ; qhasm: 2x h7 += r3    vpmuludq xmm3, xmm9, oword [rsp + 544]  ; qhasm: 2x r3 = g3 * f5_2_stack
    paddq xmm8, xmm3                       ; qhasm: 2x h8 += r3    vpmuludq xmm3, xmm9, oword [rsp + 592]  ; qhasm: 2x r3 = g3 * f6_stack
    paddq xmm7, xmm3                        ; qhasm: 2x h9 += r3
    pmuludq xmm9, [rel .v19_19]              ; qhasm: 2x g3 *= mem128[ .v19_19 ]
    vpmuludq xmm3, xmm9, oword [rsp + 640]  ; qhasm: 2x r3 = g3 * f7_2_stack
    paddq xmm11, xmm3                       ; qhasm: 2x h0 += r3
    vpmuludq xmm3, xmm9, oword [rsp + 624]  ; qhasm: 2x r3 = g3 * f8_stack
    paddq xmm13, xmm3                       ; qhasm: 2x h1 += r3
    pmuludq xmm9, oword [rsp + 704]         ; qhasm: 2x g3 *= f9_2_stack
    paddq xmm0, xmm9                        ; qhasm: 2x h2 += g3
    movdqa xmm3, oword [rsp + 32]           ; qhasm: g4 = x3_4
    movdqa xmm9, oword [rsp + 80]           ; qhasm: g5 = z3_4
    vpunpckhqdq xmm9, xmm10, [rel scratch_space + 6*16]           ; qhasm: g5 = unpack_high(g4, r)
    vpunpcklqdq xmm3, xmm10, [rel scratch_space + 6*16]           ; qhasm: g4 = unpack_low(g4, r)
    vpmuludq xmm10, xmm3, oword [rsp + 144] ; qhasm: 2x r4 = g4 * f0_stack
    paddq xmm1, xmm10                       ; qhasm: 2x h4 += r4
    vpmuludq xmm10, xmm3, oword [rsp + 128] ; qhasm: 2x r4 = g4 * f1_stack
    paddq xmm4, xmm10                       ; qhasm: 2x h5 += r4
    vpmuludq xmm10, xmm3, oword [rsp + 480] ; qhasm: 2x r4 = g4 * f2_stack
    paddq xmm6, xmm10                       ; qhasm: 2x h6 += r4
    vpmuludq xmm10, xmm3, oword [rsp + 464] ; qhasm: 2x r4 = g4 * f3_stack
    paddq xmm5, xmm10                       ; qhasm: 2x h7 += r4
    vpmuludq xmm10, xmm3, oword [rsp + 528] ; qhasm: 2x r4 = g4 * f4_stack
    paddq xmm8, xmm10                       ; qhasm: 2x h8 += r4
    vpmuludq xmm10, xmm3, oword [rsp + 512] ; qhasm: 2x r4 = g4 * f5_stak
    paddq xmm7, xmm10                       ; qhasm: 2x h9 += r4
    pmuludq xmm3, [rel .v19_19]              ; qhasm: 2x g4 *= mem128[ .v19_19 ]
    vpmuludq xmm10, xmm3, oword [rsp + 592] ; qhasm: 2x r4 = g4 * f6_stack
    paddq xmm11, xmm10                      ; qhasm: 2x h0 += r4
    vpmuludq xmm10, xmm3, oword [rsp + 576] ; qhasm: 2x r4 = g4 * f7_stack
    paddq xmm13, xmm10                      ; qhasm: 2x h1 += r4
    vpmuludq xmm10, xmm3, oword [rsp + 624] ; qhasm: 2x r4 = g4 * f8_stack
    paddq xmm0, xmm10                       ; qhasm: 2x h2 += r4
    pmuludq xmm3, oword [rsp + 672]         ; qhasm: 2x g4 *= f9_stack
    paddq xmm2, xmm3                        ; qhasm: 2x h3 += g4
    vpmuludq xmm3, xmm9, oword [rsp + 144]  ; qhasm: 2x r5 = g5 * f0_stack
    paddq xmm4, xmm3                        ; qhasm: 2x h5 += r5
    vpmuludq xmm3, xmm9, oword [rsp + 448]  ; qhasm: 2x r5 = g5 * f1_2_stack
    paddq xmm6, xmm3                        ; qhasm: 2x h6 += r5
    vpmuludq xmm3, xmm9, oword [rsp + 480]  ; qhasm: 2x r5 = g5 * f2_stack
    paddq xmm5, xmm3                        ; qhasm: 2x h7 += r5
    vpmuludq xmm3, xmm9, oword [rsp + 496]  ; qhasm: 2x r5 = g5 * f3_2_stack
    paddq xmm8, xmm3                        ; qhasm: 2x h8 += r5
    vpmuludq xmm3, xmm9,oword [rsp + 528]  ; qhasm: 2x r5 = g5 * f4_stak
    paddq xmm7, xmm3                        ; qhasm: 2x h9 += r5
    pmuludq xmm9, [rel .v19_19]              ; qhasm: 2x g5 *= mem128[ .v19_19 ]
    vpmuludq xmm3, xmm9, oword [rsp + 544]  ; qhasm: 2x r5 = g5 * f5_2_stack
    paddq xmm11, xmm3                       ; qhasm: 2x h0 += r5
    vpmuludq xmm3, xmm9, oword [rsp + 592]  ; qhasm: 2x r5 = g5 * f6_stack
    paddq xmm13, xmm3                       ; qhasm: 2x h1 += r5
    vpmuludq xmm3, xmm9, oword [rsp + 640]  ; qhasm: 2x r5 = g5 * f7_2_stack
    paddq xmm0, xmm3                        ; qhasm: 2x h2 += r5
    vpmuludq xmm3, xmm9, oword [rsp + 624]  ; qhasm: 2x r5 = g5 * f8_stack
    paddq xmm2, xmm3                        ; qhasm: 2x h3 += r5
    pmuludq xmm9, oword [rsp + 704]         ; qhasm: 2x g5 *= f9_2_stack
    paddq xmm1, xmm9                        ; qhasm: 2x h4 += g5
    movdqa xmm3, oword [rsp + 48]           ; qhasm: g6 = x3_6
    movdqa xmm9, oword [rsp + 96]           ; qhasm: g7 = z3_6
    vpunpckhqdq xmm9, xmm10, [rel scratch_space + 7*16]           ; qhasm: g7 = unpack_high(g6, r)
    vpunpcklqdq xmm3, xmm10, [rel scratch_space + 7*16]           ; qhasm: g6 = unpack_low(g6, r)
    vpmuludq xmm10, xmm3, oword [rsp + 144] ; qhasm: 2x r6 = g6 * f0_stack
    paddq xmm6, xmm10                       ; qhasm: 2x h6 += r6
    vpmuludq xmm10, xmm3, oword [rsp + 128] ; qhasm: 2x r6 = g6 * f1_stack
    paddq xmm5, xmm10                       ; qhasm: 2x h7 += r6
    vpmuludq xmm10, xmm3, oword [rsp + 480] ; qhasm: 2x r6 = g6 * f2_stack
    paddq xmm8, xmm10                       ; qhasm: 2x h8 += r6
    vpmuludq xmm10, xmm3, oword [rsp + 464] ; qhasm: 2x r6 = g6 * f3_stak
    paddq xmm7, xmm10                       ; qhasm: 2x h9 += r6
    pmuludq xmm3, [rel .v19_19]              ; qhasm: 2x g6 *= mem128[ .v19_19 ]
    vpmuludq xmm10, xmm3, oword [rsp + 528] ; qhasm: 2x r6 = g6 * f4_stack
    paddq xmm11, xmm10                      ; qhasm: 2x h0 += r6
    vpmuludq xmm10, xmm3, oword [rsp + 512] ; qhasm: 2x r6 = g6 * f5_stack
    paddq xmm13, xmm10                      ; qhasm: 2x h1 += r6
    vpmuludq xmm10, xmm3, oword [rsp + 592] ; qhasm: 2x r6 = g6 * f6_stack
    paddq xmm0, xmm10                       ; qhasm: 2x h2 += r6
    vpmuludq xmm10, xmm3, oword [rsp + 576] ; qhasm: 2x r6 = g6 * f7_stack
    paddq xmm2, xmm10                       ; qhasm: 2x h3 += r6
    vpmuludq xmm10, xmm3, oword [rsp + 624] ; qhasm: 2x r6 = g6 * f8_stack
    paddq xmm1, xmm10                       ; qhasm: 2x h4 += r6
    pmuludq xmm3, oword [rsp + 672]         ; qhasm: 2x g6 *= f9_stack
    paddq xmm4, xmm3                        ; qhasm: 2x h5 += g6
    vpmuludq xmm3, xmm9, oword [rsp + 144]  ; qhasm: 2x r7 = g7 * f0_stack
    paddq xmm5, xmm3                        ; qhasm: 2x h7 += r7
    vpmuludq xmm3, xmm9, oword [rsp + 448]  ; qhasm: 2x r7 = g7 * f1_2_stack
    paddq xmm8, xmm3                        ; qhasm: 2x h8 += r7
    vpmuludq xmm3, xmm9,oword [rsp + 480]  ; qhasm: 2x r7 = g7 * f2_stak
    paddq xmm7, xmm3                        ; qhasm: 2x h9 += r7
    pmuludq xmm9, [rel .v19_19]              ; qhasm: 2x g7 *= mem128[ .v19_19 ]
    vpmuludq xmm3, xmm9, oword [rsp + 496]  ; qhasm: 2x r7 = g7 * f3_2_stack
    paddq xmm11, xmm3                       ; qhasm: 2x h0 += r7
    vpmuludq xmm3, xmm9, oword [rsp + 528]  ; qhasm: 2x r7 = g7 * f4_stack
    paddq xmm13, xmm3                       ; qhasm: 2x h1 += r7
    vpmuludq xmm3, xmm9, oword [rsp + 544]  ; qhasm: 2x r7 = g7 * f5_2_stack
    paddq xmm0, xmm3                        ; qhasm: 2x h2 += r7
    vpmuludq xmm3, xmm9, oword [rsp + 592]  ; qhasm: 2x r7 = g7 * f6_stack
    paddq xmm2, xmm3                        ; qhasm: 2x h3 += r7
    vpmuludq xmm3, xmm9, oword [rsp + 640]  ; qhasm: 2x r7 = g7 * f7_2_stack
    paddq xmm1, xmm3                        ; qhasm: 2x h4 += r7
    vpmuludq xmm3, xmm9, oword [rsp + 624]  ; qhasm: 2x r7 = g7 * f8_stack
    paddq xmm4, xmm3                        ; qhasm: 2x h5 += r7
    pmuludq xmm9, oword [rsp + 704]         ; qhasm: 2x g7 *= f9_2_stack
    paddq xmm6, xmm9                        ; qhasm: 2x h6 += g7
    movdqa xmm3, oword [rsp + 64]           ; qhasm: g8 = x3_8
    movdqa xmm9, oword [rsp + 112]          ; qhasm: g9 = z3_8
    vpunpckhqdq xmm9, xmm10, [rel scratch_space + 8*16]           ; qhasm: g9 = unpack_high(g8, r)
    vpunpcklqdq xmm3, xmm10, [rel scratch_space + 8*16]           ; qhasm: g8 = unpack_low(g8, r)
    vpmuludq xmm10, xmm3, oword [rsp + 144] ; qhasm: 2x r8 = g8 * f0_stack
    paddq xmm8, xmm10                       ; qhasm: 2x h8 += r8
    vpmuludq xmm10, xmm3, oword [rsp + 128] ; qhasm: 2x r8 = g8 * f1_stak
    paddq xmm7, xmm10                       ; qhasm: 2x h9 += r8
    pmuludq xmm3, [rel .v19_19]              ; qhasm: 2x g8 *= mem128[ .v19_19 ]
    vpmuludq xmm10, xmm3, oword [rsp + 480] ; qhasm: 2x r8 = g8 * f2_stack
    paddq xmm11, xmm10                      ; qhasm: 2x h0 += r8
    vpmuludq xmm10, xmm3, oword [rsp + 464] ; qhasm: 2x r8 = g8 * f3_stack
    paddq xmm13, xmm10                      ; qhasm: 2x h1 += r8
    vpmuludq xmm10, xmm3, oword [rsp + 528] ; qhasm: 2x r8 = g8 * f4_stack
    paddq xmm0, xmm10                       ; qhasm: 2x h2 += r8
    vpmuludq xmm10, xmm3, oword [rsp + 512] ; qhasm: 2x r8 = g8 * f5_stack
    paddq xmm2, xmm10                       ; qhasm: 2x h3 += r8
    vpmuludq xmm10, xmm3, oword [rsp + 592] ; qhasm: 2x r8 = g8 * f6_stack
    paddq xmm1, xmm10                       ; qhasm: 2x h4 += r8
    vpmuludq xmm10, xmm3, oword [rsp + 576] ; qhasm: 2x r8 = g8 * f7_stack
    paddq xmm4, xmm10                       ; qhasm: 2x h5 += r8
    vpmuludq xmm10, xmm3, oword [rsp + 624] ; qhasm: 2x r8 = g8 * f8_stack
    paddq xmm6, xmm10                       ; qhasm: 2x h6 += r8
    pmuludq xmm3, oword [rsp + 672]         ; qhasm: 2x g8 *= f9_stack
    paddq xmm5, xmm3                        ; qhasm: 2x h7 += g8
    vpmuludq xmm3, xmm9,oword [rsp + 144]  ; qhasm: 2x r9 = g9 * f0_stak
    paddq xmm7, xmm3                        ; qhasm: 2x h9 += r9
    pmuludq xmm9, [rel .v19_19]              ; qhasm: 2x g9 *= mem128[ .v19_19 ]
    vpmuludq xmm3, xmm9, oword [rsp + 448]  ; qhasm: 2x r9 = g9 * f1_2_stack
    paddq xmm11, xmm3                       ; qhasm: 2x h0 += r9
    vpmuludq xmm3, xmm9, oword [rsp + 480]  ; qhasm: 2x r9 = g9 * f2_stack
    paddq xmm13, xmm3                       ; qhasm: 2x h1 += r9
    vpmuludq xmm3, xmm9, oword [rsp + 496]  ; qhasm: 2x r9 = g9 * f3_2_stack
    paddq xmm0, xmm3                        ; qhasm: 2x h2 += r9
    vpmuludq xmm3, xmm9, oword [rsp + 528]  ; qhasm: 2x r9 = g9 * f4_stack
    paddq xmm2, xmm3                        ; qhasm: 2x h3 += r9
    vpmuludq xmm3, xmm9, oword [rsp + 544]  ; qhasm: 2x r9 = g9 * f5_2_stack
    paddq xmm1, xmm3                        ; qhasm: 2x h4 += r9
    vpmuludq xmm3, xmm9, oword [rsp + 592]  ; qhasm: 2x r9 = g9 * f6_stack
    paddq xmm4, xmm3                        ; qhasm: 2x h5 += r9
    vpmuludq xmm3, xmm9, oword [rsp + 640]  ; qhasm: 2x r9 = g9 * f7_2_stack
    paddq xmm6, xmm3                        ; qhasm: 2x h6 += r9
    vpmuludq xmm3, xmm9, oword [rsp + 624]  ; qhasm: 2x r9 = g9 * f8_stack
    paddq xmm5, xmm3                        ; qhasm: 2x h7 += r9
    pmuludq xmm9, oword [rsp + 704]         ; qhasm: 2x g9 *= f9_2_stack
    paddq xmm8, xmm9                        ; qhasm: 2x h8 += g9

    mov rsp, rbp
    pop rbp
    bench_epilogue
    ret

section .rodata:
align 16, db 0
.v19_19: dq 19, 19
