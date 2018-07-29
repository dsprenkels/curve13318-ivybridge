; Field arithmetic for integers modulo 2^255 - 19
;
; Author: Amber Sprenkels <amber@electricdusk.com>

section .text

global crypto_scalarmult_curve13318_ref12_fe12x4_squeeze


crypto_scalarmult_curve13318_ref12_fe12x4_squeeze:
    ; Interleave two carry chains (8 rounds):
    ;   - a: z[0] -> z[1] -> z[2] -> z[3] -> z[4]  -> z[5]  -> z[6] -> z[7]
    ;   - b: z[6] -> z[7] -> z[8] -> z[9] -> z[10] -> z[11] -> z[0] -> z[1]
    ;
    ; Input:  one vectorized field element (ymm0..ymm11) [rdi]
    ; Output: one vectorized field element (ymm0..ymm11) [rdi]
    ;
    ; Precondition:
    ;   - For all limbs x in z : |x| <= 0.99 * 2^53
    ;
    ; Postcondition:
    ;   - All significands fit in b + 1 bits (b = 22, 21, 21, etc.)
    ;
    ; Registers:
    ;   - ymm0..ymm11:  four input and output field elments
    ;   - ymm12,ymm13:  large values to force precision loss
    ;   - ymm14,ymm15:  two temporary registers for t0 and t1

    ; load field element
    vmovdqa ymm0, yword [rdi]
    vmovdqa ymm1, yword [rdi+32]
    vmovdqa ymm2, yword [rdi+64]
    vmovdqa ymm3, yword [rdi+96]
    vmovdqa ymm4, yword [rdi+128]
    vmovdqa ymm5, yword [rdi+160]
    vmovdqa ymm6, yword [rdi+192]
    vmovdqa ymm7, yword [rdi+224]
    vmovdqa ymm8, yword [rdi+256]
    vmovdqa ymm9, yword [rdi+288]
    vmovdqa ymm10, yword [rdi+320]
    vmovdqa ymm11, yword [rdi+352]

%macro fe12x4_squeeze_inner 0
    ; load precisionloss values
    vbroadcastsd ymm12, qword [rel precisionloss0]
    vbroadcastsd ymm13, qword [rel precisionloss6]

    ; round 1
    vaddpd ymm14, ymm0, ymm12
    vaddpd ymm15, ymm6, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vbroadcastsd ymm12, qword [rel precisionloss1]
    vbroadcastsd ymm13, qword [rel precisionloss7]
    vaddpd ymm1, ymm1, ymm14
    vaddpd ymm7, ymm7, ymm15
    vsubpd ymm0, ymm0, ymm14
    vsubpd ymm6, ymm6, ymm15

    ; round 2
    vaddpd ymm14, ymm1, ymm12
    vaddpd ymm15, ymm7, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vbroadcastsd ymm12, qword [rel precisionloss2]
    vbroadcastsd ymm13, qword [rel precisionloss8]
    vaddpd ymm2, ymm2, ymm14
    vaddpd ymm8, ymm8, ymm15
    vsubpd ymm1, ymm1, ymm14
    vsubpd ymm7, ymm7, ymm15

    ; round 3
    vaddpd ymm14, ymm2, ymm12
    vaddpd ymm15, ymm8, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vbroadcastsd ymm12, qword [rel precisionloss3]
    vbroadcastsd ymm13, qword [rel precisionloss9]
    vaddpd ymm3, ymm3, ymm14
    vaddpd ymm9, ymm9, ymm15
    vsubpd ymm2, ymm2, ymm14
    vsubpd ymm8, ymm8, ymm15

    ; round 4
    vaddpd ymm14, ymm3, ymm12
    vaddpd ymm15, ymm9, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vbroadcastsd ymm12, qword [rel precisionloss4]
    vbroadcastsd ymm13, qword [rel precisionloss10]
    vaddpd ymm4, ymm4, ymm14
    vaddpd ymm10, ymm10, ymm15
    vsubpd ymm3, ymm3, ymm14
    vsubpd ymm9, ymm9, ymm15

    ; round 5
    vaddpd ymm14, ymm4, ymm12
    vaddpd ymm15, ymm10, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vbroadcastsd ymm12, qword [rel precisionloss5]
    vbroadcastsd ymm13, qword [rel precisionloss11]
    vaddpd ymm5, ymm5, ymm14
    vaddpd ymm11, ymm11, ymm15
    vsubpd ymm4, ymm4, ymm14
    vsubpd ymm10, ymm10, ymm15

    ; round 6
    vaddpd ymm14, ymm5, ymm12
    vaddpd ymm15, ymm11, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vbroadcastsd ymm13, qword [rel reduceconstant]
    vsubpd ymm5, ymm5, ymm14
    vsubpd ymm11, ymm11, ymm15
    vmulpd ymm15, ymm15, ymm13
    vbroadcastsd ymm12, qword [rel precisionloss6]
    vbroadcastsd ymm13, qword [rel precisionloss0]
    vaddpd ymm6, ymm6, ymm14
    vaddpd ymm0, ymm0, ymm15

    ; round 7
    vaddpd ymm14, ymm6, ymm12
    vaddpd ymm15, ymm0, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vbroadcastsd ymm12, qword [rel precisionloss7]
    vbroadcastsd ymm13, qword [rel precisionloss1]
    vaddpd ymm7, ymm7, ymm14
    vaddpd ymm1, ymm1, ymm15
    vsubpd ymm6, ymm6, ymm14
    vsubpd ymm0, ymm0, ymm15

    ; round 8
    vaddpd ymm14, ymm7, ymm12
    vaddpd ymm15, ymm1, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vaddpd ymm8, ymm8, ymm14
    vaddpd ymm2, ymm2, ymm15
    vsubpd ymm7, ymm7, ymm14
    vsubpd ymm1, ymm1, ymm15
%endmacro
    fe12x4_squeeze_inner

    ; store field element
    vmovdqa yword [rdi], ymm0
    vmovdqa yword [rdi+32], ymm1
    vmovdqa yword [rdi+64], ymm2
    vmovdqa yword [rdi+96], ymm3
    vmovdqa yword [rdi+128], ymm4
    vmovdqa yword [rdi+160], ymm5
    vmovdqa yword [rdi+192], ymm6
    vmovdqa yword [rdi+224], ymm7
    vmovdqa yword [rdi+256], ymm8
    vmovdqa yword [rdi+288], ymm9
    vmovdqa yword [rdi+320], ymm10
    vmovdqa yword [rdi+352], ymm11

    ret


section .rodata:

align 8, db 0
precisionloss0: dq 0x3p73
precisionloss1: dq 0x3p94
precisionloss2: dq 0x3p115
precisionloss3: dq 0x3p136
precisionloss4: dq 0x3p158
precisionloss5: dq 0x3p179
precisionloss6: dq 0x3p200
precisionloss7: dq 0x3p221
precisionloss8: dq 0x3p243
precisionloss9: dq 0x3p264
precisionloss10: dq 0x3p285
precisionloss11: dq 0x3p306
reduceconstant: dq 0x13p-255
