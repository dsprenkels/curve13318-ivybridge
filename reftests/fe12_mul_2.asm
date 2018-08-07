section .text

global fe12_mul_2

fe12_mul_2:
    %define A rsi
    %define B rdx
    %define h rdi
    %define Ax_shr rsp+0
    %define l rsp+192

    ; TODO(dsprenkels) After writing the first piece of code, I have noticed that it is really
    ; register-greedy. I want to try what happens if we only load the accumulators and the A-values
    ; and load (most of) the B-values directly from cache in a vmulpd instruction.

    ; build stack frame
    push rbp
    mov rbp, rsp
    and rsp, -32
    sub rsp, 1056

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
    ; TODO(dsprenkels) Check if this optimisation actually helps.
    vmovapd ymm8, yword [rel const_1_1p_neg128]
    vmovapd ymm9, yword [rel const_unset_bit59_mask]
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

    ; Just as in the computation of L, we will store the accumulators (h) in ymm10..ymm15
    ; round 1/6
    vmulpd ymm10, ymm6, ymm0            ; h0 :=  A6_shr *  B6_shr
    vmovapd yword [h], ymm10            ; store h0
    vmulpd ymm11, ymm6, ymm1            ; h1 :=  A6_shr *  B7_shr
    vmulpd ymm12, ymm6, ymm2            ; h2 :=  A6_shr *  B8_shr
    vmulpd ymm13, ymm6, ymm3            ; h3 :=  A6_shr *  B9_shr
    vmulpd ymm14, ymm6, ymm4            ; h4 :=  A6_shr * B10_shr
    vmulpd ymm15, ymm6, ymm5            ; h5 :=  A6_shr * B11_shr
    vmovapd yword [Ax_shr], ymm6        ; spill A6_shr
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
    vmovapd yword [h+192], ymm10        ; store l6
    vmulpd ymm8, ymm7, ymm2
    vaddpd ymm11, ymm11, ymm8           ; h7 += A11_shr *  B8_shr
    vmovapd yword [h+224], ymm11        ; store l7
    vmulpd ymm8, ymm7, ymm3
    vaddpd ymm12, ymm12, ymm8           ; h8 += A11_shr *  B9_shr
    vmovapd yword [h+256], ymm12        ; store l8
    vmulpd ymm8, ymm7, ymm4
    vaddpd ymm13, ymm13, ymm8           ; h9 += A11_shr * B10_shr
    vmovapd yword [h+288], ymm13        ; store l9
    vmulpd ymm14, ymm7, ymm5            ; h10 := A11_shr * B11_shr
    vmovapd yword [h+320], ymm14        ; store l10

    ; Restore stack frame
    mov rsp, rbp
    pop rbp
    ret

section .rodata:

align 32, db 0
const_unset_bit59_mask: times 4 dq 0xF7FFFFFFFFFFFFFF
const_1_1p_neg128: times 4 dq 0x1p-128
