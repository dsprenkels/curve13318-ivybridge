; Multiplication function for field elements (integers modulo 2^255 - 19)
;
; Author: Amber Sprenkels <amber@electricdusk.com>

%include "bench.asm"

section .rodata:

_bench1_name: db `fe12_mul\0`
_bench2_name: db `fe12_mul_gcc\0`

align 8, db 0
_bench_fns_arr:
dq fe12_mul, fe12_mul_gcc

_bench_names_arr:
dq _bench1_name, _bench2_name

_bench_fns: dq _bench_fns_arr
_bench_names: dq _bench_names_arr
_bench_fns_n: dd 2

section .bss
align 32
scratch_space: resb 1536

section .text

global fe12_mul

fe12_mul:
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

    ; notes:
    ;             latency | throughput | ports
    ;   - vmulpd:       5 |          1 |     0
    ;   - vaddpd:       3 |          1 |     1
    ;   - load:         4 |          1 |     2,3

    ; compute L
    ; ymm9 will store intermediate values, ymm10..ymm15 will store the accumulators
    vmovapd ymm6, yword [A]         ; load A[0]
    vmovapd ymm7, yword [A+32]      ; load A[1]
    vmovapd ymm0, yword [B]         ; load B[0]
    vmovapd ymm1, yword [B+32]      ; load B[1]
    vmovapd ymm2, yword [B+64]      ; load B[2]
    vmovapd ymm3, yword [B+96]      ; load B[3]
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
    ; TODO(dsprenkels) Check if this optimisation actually helps.
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
