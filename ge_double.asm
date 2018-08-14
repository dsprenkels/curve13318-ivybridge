; Doubling of group elements
;
; Author: Amber Sprenkels <amber@electricdusk.com>

section .text
global crypto_scalarmult_curve13318_ref12_ge_double
extern crypto_scalarmult_curve13318_ref12_fe12x4_mul, crypto_scalarmult_curve13318_ref12_fe12x4_squeeze

crypto_scalarmult_curve13318_ref12_ge_double:
    ; The next chain of procedures is an adapted version of  Algorithm 6
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
    %push ge_double_ctx
    %define x3          rdi
    %define y3          rdi + 12*8
    %define z3          rdi + 24*8
    %define x           rsi
    %define y           rsi + 12*8
    %define z           rsi + 24*8
    %define t0          rsp
    %define t1          rsp + 1*384
    %define t2          rsp + 2*384
    %define t3          rsp + 3*384
    %define t4          rsp + 4*384
    %define t5          rsp + 5*384
    %define v11         rsp + 6*384
    %define v34         rsp + 6*384 + 1*96
    %define v26v30      rsp + 6*384 + 2*96
    %define old_rdi     rsp + 7*384
    %define stack_size  7*384 + 32

    ; build stack frame
    push rbp
    mov rbp, rsp
    and rsp, -32
    sub rsp, (stack_size)
    mov qword [old_rdi], rdi ; we are going to overwrite this during function calls

    %assign i 0
    %rep 12
        vbroadcastsd ymm0, qword [x + i*8]  ; [x, x, x, x]
        vbroadcastsd ymm1, qword [y + i*8]  ; [y, y, y, y]
        vbroadcastsd ymm2, qword [z + i*8]  ; [z, z, z, z]
        vblendpd ymm3, ymm0, ymm2, 0b1100   ; [x, x, z, z]
        vblendpd ymm4, ymm0, ymm2, 0b0110   ; [x, z, z, x]
        vblendpd ymm4, ymm4, ymm1, 0b1000   ; [x, z, z, y]
        vmovapd yword [t0 + i*32], ymm3
        vmovapd yword [t1 + i*32], ymm4
        ; prepare for second mul
        vmovapd oword [t3 + i*32], xmm1     ; t3 = [y, y, ??, ??]
        vmovsd qword [t4 + i*32], xmm1      ; t4 = [y, ??, ??, ??]
        vmovsd qword [t4 + i*32 + 8],xmm0   ; t4 = [y, x, ??, ??]
    %assign i i+1
    %endrep

    lea rdi, [t2]
    lea rsi, [t0]
    lea rdx, [t1]
    call crypto_scalarmult_curve13318_ref12_fe12x4_mul wrt ..plt
    call crypto_scalarmult_curve13318_ref12_fe12x4_squeeze wrt ..plt

    vmovapd ymm0, [rel .const_mulsmall]
    %assign i 0
    %rep 12
        vmovapd ymm1, [t2 + 32*i]               ; [v1, v6, v3, v28]
        vpermilpd ymm2, ymm1, 0b0010            ; [v1, v6, v3, v3]
        vmulpd ymm2, ymm2, ymm0                 ; computing [v24, v18, v8, v17]
        vextractf128 xmm3, ymm2, 0b1            ; [v8, v17]
        vpermilpd xmm4, xmm3, 0b1               ; [v17, v8]
        vaddsd xmm5, xmm2, xmm4                 ; computing v25
        vpermilpd xmm2, xmm2, 0b1               ; [v18, v24]
        vaddsd xmm6, xmm2, xmm4                 ; computing v19
        vsubsd xmm6, xmm1, xmm6                 ; computing v20
        vmulsd xmm6, xmm6, [rel .const_neg3]    ; computing v22
        vpermilpd xmm1, xmm1, 0b1               ; [v6, v1]
        vaddsd xmm7, xmm3, xmm1                 ; computing v9
        vmulsd xmm7, xmm7, [rel .const_neg6]    ; computing v11
        vmovsd qword [v11 + 8*i], xmm7          ; spill v11

        vmovsd qword [t3 + i*32 + 16], xmm6     ; t3 = [y, y, v22, ??]
        vmovsd qword [t3 + i*32 + 24], xmm6     ; t3 = [y, y, v22, v22]
        vmovsd qword [t4 + i*32 + 16], xmm5     ; t4 = [y, x, v25, ??]

        ; put r29 in t4
        vmovsd xmm8, qword [t2 + i*32 + 24]
        vmulsd xmm9, xmm8, qword [rel .const_2] ; computing v29a
        vmovsd qword [t4 + i*32 + 24], xmm9     ; t4 = [y, x, v25, v29a]
        vmulsd xmm10, xmm8, qword [rel .const_8]; computing v34
        vmovsd qword [v34 + i*8], xmm10         ; spill v34
    %assign i i+1
    %endrep

    lea rdi, [t3]
    call crypto_scalarmult_curve13318_ref12_fe12x4_squeeze wrt ..plt
    lea rdi, [t4]
    call crypto_scalarmult_curve13318_ref12_fe12x4_squeeze wrt ..plt
    lea rdi, [t5]
    lea rsi, [t3]
    lea rdx, [t4]
    call crypto_scalarmult_curve13318_ref12_fe12x4_mul wrt ..plt
    call crypto_scalarmult_curve13318_ref12_fe12x4_squeeze wrt ..plt

    ; for the third batched multiplication we'll reuse {t0,t1,t2}
    %assign i 0
    %rep 12
        vmovapd ymm0, [t5 + i*32]               ; [v2, v4, v26, v30]
        vmovsd xmm2, qword [v11 + i*8]          ; v11
        vsubsd xmm3, xmm0, xmm2                 ; computing v12
        vaddsd xmm4, xmm0, xmm2                 ; computing v13
        vpermilpd xmm5, xmm0, 0b1               ; [v4, v2]
        vmulsd xmm5, xmm5, qword [rel .const_2] ; computing v5
        vmovsd qword [t0 + 32*i], xmm3          ; t0 = [v12, ??, ??, ??]
        vmovsd qword [t0 + 32*i + 8], xmm3      ; t0 = [v12, v12, ??, ??]
        vmovsd qword [t0 + 32*i + 16], xmm0     ; t0 = [v12, v12, v2, ??]
        vmovsd qword [t1 + 32*i], xmm5          ; t1 = [v5, ??, ??, ??]
        vmovsd qword [t1 + 32*i + 8], xmm4      ; t1 = [v5, v13, ??, ??]
        vmovsd xmm6, qword [v34 + i*8]          ; reload v34
        vmovsd qword [t1 + 32*i + 16], xmm6     ; t1 = [v5, v13, v34, ??]
        vextractf128 xmm7, ymm0, 0b1            ; [v26, v30]
        movapd oword [v26v30 + 16*i], xmm7      ; spill [v26, v30]
    %assign i i+1
    %endrep

    lea rdi, [t0]
    call crypto_scalarmult_curve13318_ref12_fe12x4_squeeze wrt ..plt
    lea rdi, [t1]
    call crypto_scalarmult_curve13318_ref12_fe12x4_squeeze wrt ..plt
    lea rdi, [t2]
    lea rsi, [t0]
    lea rdx, [t1]
    call crypto_scalarmult_curve13318_ref12_fe12x4_mul wrt ..plt
    call crypto_scalarmult_curve13318_ref12_fe12x4_squeeze wrt ..plt

    mov rdi, qword [old_rdi]
    %assign i 0
    %rep 12
        vmovapd ymm0, [t2 + i*32]               ; [v15, v14, v32, ??]
        vpermilpd xmm1, xmm0, 0b1               ; [v14, v15]
        vsubsd xmm2, xmm0, qword [v26v30 + 16*i + 8] ; v31
        vaddsd xmm3, xmm1, qword [v26v30 + 16*i]; v27
        vextractf128 xmm4, ymm0, 0b1            ; [v32, ??]
        ; save doubled point
        vmovsd qword [x3 + 8*i], xmm2           ; store x3
        vmovsd qword [y3 + 8*i], xmm3           ; store y3
        vmovsd qword [z3 + 8*i], xmm4           ; store z3
    %assign i i+1
    %endrep

    %pop ge_double_ctx

    ; restore stack frame
    mov rsp, rbp
    pop rbp
    ret

section .rodata

.const_neg3:    dq -3.0
.const_neg6:    dq -6.0
.const_2:       dq 2.0
.const_8:       dq 8.0
align 32,       db 0
.const_mulsmall: dq 3.0, 26636.0, -6659.0, -3.0
