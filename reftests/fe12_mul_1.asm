section .text

global fe12_mul_1

fe12_mul_1:
    %define A rsi
    %define B rdx
    %define l rdi

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

    ret
