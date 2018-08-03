; Multiplication function for field elements (integers modulo 2^255 - 19)
;
; Author: Amber Sprenkels <amber@electricdusk.com>

section .text

global crypto_scalarmult_curve13318_ref12_fe12x4_squeeze

crypto_scalarmult_curve13318_ref12_fe12x4_mul:
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
    %define Ax_shr rsp+0
    %define Bx_shr rsp+192
    %define mAx rsp+384
    %define mBx rsp+576
    %define l rsp+768
    %define m rsp+1120
    %define h rsp+1442

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

    ; compute l
    ; TODO: put the pseudocode for computing l in a comment above the code
    vmovapd ymm0, yword [B]         ; load B[0]
    vmovapd ymm1, yword [A]         ; load A[0]
    vmovapd ymm2, yword [B+32]      ; load B[1]
    vmovapd ymm3, yword [A+32]      ; load A[1]
    vmovapd ymm4, yword [B+64]      ; load B[2]
    vmulpd ymm15, ymm1, ymm0        ; A[0] * B[0]       (l0)
    vmovapd ymm5, yword [A+64]      ; load A[2]
    vmulpd ymm14, ymm1, ymm2        ; A[0] * B[1]       (l1)
    vmulpd ymm13, ymm3, ymm0        ; A[1] * B[0]       (l1)
    vmovapd ymm6, yword [B+96]      ; load B[3]
    vmulpd ymm12, ymm3, ymm2        ; A[1] * B[1]       (l2)
    vmovapd ymm7, yword [A+96]      ; load A[3]
    vmulpd ymm11, ymm1, ymm4        ; A[0] * B[2]       (l2)
    vaddpd ymm14, ymm14, ymm13      ; accum [xx....]    (l1)
    vmovapd yword [l], ymm15        ; store l0
    vmulpd ymm13, ymm5, ymm0        ; A[2] * B[0]       (l2)
    vmulpd ymm15, ymm3, ymm4        ; A[1] * B[2]       (l3)
    vaddpd ymm12, ymm12, ymm11      ; accum [xx_...]    (l2)
    vmovapd yword [l+32], ymm14     ; store l1
    vmulpd ymm11, ymm5, ymm2        ; A[2] * B[1]       (l3)
    vmulpd ymm14, ymm1, ymm6        ; A[0] * B[3]       (l3)
    vmovapd ymm8, yword [B+128]     ; load B[4]
    ; short on registers here, so I have to prioritize on accumulating instead of parallelism
    vmulpd ymm10, ymm7, ymm0        ; A[3] * B[0]       (l3)
    vaddpd ymm12, ymm12, ymm13      ; accum [xxx...]    (l2)
    vmulpd ymm13, ymm5, ymm4        ; A[2] * B[2]       (l4)
    vmovapd ymm9, yword [A+128]     ; load A[4]
    vaddpd ymm15, ymm15, ymm11      ; accum [_xx_..]    (l3)
    vmulpd ymm11, ymm3, ymm6        ; A[1] * B[3]       (l4)
    vaddpd ymm14, ymm14, ymm10      ; accum [x__x..]    (l3)
    vmulpd ymm10, ymm7, ymm2        ; A[3] * B[1]       (l4)
    vmovapd yword [l+64], ymm12     ; store l2
    vmulpd ymm12, ymm1, ymm8        ; A[0] * B[4]       (l4)
    vaddpd ymm15, ymm15, ymm14      ; accum [xxxx..]    (l3)
    vmulpd ymm14, ymm9, ymm0        ; A[4] * B[0]       (l4)
    vaddpd ymm13, ymm13, ymm11      ; accum [_xx__.]    (l4)
    vmulpd ymm11, ymm5, ymm6        ; A[2] * B[3]       (l5)
    vaddpd ymm10, ymm10, ymm12      ; accum [x__x_.]    (l4)
    vmulpd ymm12, ymm7, ymm4        ; A[3] * B[2]       (l5)
    vmovapd yword [l+96], ymm15     ; store l3
    vmulpd ymm15, ymm3, ymm8        ; A[1] * B[4]       (l5)
    vaddpd ymm13, ymm13, ymm14      ; accum [_xx_x.]    (l4)
    vmulpd ymm14, ymm9, ymm2        ; A[4] * B[1]       (l5)
    vaddpd ymm11, ymm11, ymm12      ; accum [__xx__]    (l5)
    vmulpd ymm12, ymm7, ymm6        ; A[3] * B[3]       (l6)
    vaddpd ymm13, ymm13, ymm10      ; accum [xxxxx.]    (l4)
    vmulpd ymm10, ymm5, ymm8        ; A[2] * B[4]       (l6)
    vaddpd ymm15, ymm15, ymm14      ; accum [_x__x_]    (l5)
    vmovapd ymm14, yword [B+160]    ; load B[5]
    vmovapd yword [l+128], ymm13    ; store l4
    ; have enough registers again; focus on parallelism (i.e. start computing l7)
    vmulpd ymm13, ymm9, ymm4        ; A[4] * B[2]       (l6)
    vmulpd ymm1, ymm1, ymm14        ; A[0] * B[5]       (l5), last use of A[0]
    vaddpd ymm12, ymm12, ymm10      ; accum [._xx__]    (l6)
    vmulpd ymm3, ymm3, ymm14        ; A[1] * B[5]       (l6), last use of A[1]
    vmovapd ymm10, yword [A+160]    ; load A[5]
    vmulpd ymm5, ymm5, ymm14        ; A[2] * B[5]       (l7), last use of A[2]
    vaddpd ymm11, ymm11, ymm15      ; accum [_xxxx_]    (l5)
    vmulpd ymm15, ymm7, ymm8        ; A[3] * B[4]       (l7)
    vaddpd ymm12, ymm12, ymm13      ; accum [._xxx_]    (l6)
    vmulpd ymm0, ymm0, ymm10        ; A[5] * B[0]       (l5), last use of B[0]
    vmulpd ymm2, ymm10, ymm2        ; A[5] * B[1]       (l6), last use of B[1]
    vaddpd ymm11, ymm11, ymm1       ; accum [xxxxx_]    (l5)
    vmulpd ymm7, ymm7, ymm14        ; A[3] * B[5]       (l8), last use of A[3]
    vmulpd ymm13, ymm9, ymm6        ; A[4] * B[3]       (l7)
    vaddpd ymm12, ymm12, ymm3       ; accum [.xxxx_]    (l6)
    vmulpd ymm1, ymm9, ymm8         ; A[4] * B[4]       (l8)
    vaddpd ymm11, ymm11, ymm0       ; accum [xxxxxx]    (l5)
    vmulpd ymm9, ymm9, ymm14        ; A[4] * B[5]       (l9), last use of A[4]
    vaddpd ymm5, ymm5, ymm15        ; accum [..xx__]    (l7)
    vmulpd ymm3, ymm10, ymm4        ; A[5] * B[2]       (l7)
    vaddpd ymm12, ymm12, ymm2       ; accum [.xxxxx]    (l6)
    vmulpd ymm15, ymm10, ymm6       ; A[5] * B[3]       (l8)
    vmovapd yword [l+160], ymm11    ; store l5
    vaddpd ymm7, ymm7, ymm1         ; accum [...xx_]    (l8)
    vmulpd ymm8, ymm10, ymm8        ; A[5] * B[4]       (l9), last use of B[4]
    vaddpd ymm5, ymm5, ymm13        ; accum [..xxx_]    (l7)
    vmulpd ymm10, ymm10, ymm14      ; A[5] * B[5]       (l10), last multiplication for l
    vmovapd yword [l+192], ymm12    ; store l6
    ; MARK(dsprenkels) Stopped pipelining here.
    vaddpd ymm7, ymm7, ymm15        ; accum [...xxx]    (l8)
    vaddpd ymm5, ymm5, ymm3         ; accum [..xxxx]    (l7)
    vaddpd ymm9, ymm9, ymm8         ; accum [....xx]    (l9)
    vmovapd yword [l+256], ymm7     ; store l8
    vmovapd yword [l+224], ymm5     ; store l7
    vmovapd yword [l+288], ymm9     ; store l9
    vmovapd yword [l+320], ymm10    ; store l10

    ; TODO(dsprenkels) Left here

    ; Restore stack frame
    mov rsp, rbp
    pop rbp
    ret


section .rodata

align 8, db 0

const_1_1p_neg128: times 4 dq 0x1p-128
const_1_1p_128: times 4 dq 0x1p+128
const_38: times 4 dq 0x26
const_38_1p_neg128: times 4 dq 0x26p-128
