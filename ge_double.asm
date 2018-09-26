; Doubling of group elements
;
; Author: Amber Sprenkels <amber@electricdusk.com>

%include "fe12_mul.mac"

global crypto_scalarmult_curve13318_ref12_ge_double

section .text
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
    ; TODO(dsprenkels) Vectorise 5 and 29a
    ;
    %push ge_double_ctx
    %xdefine x3          rdi
    %xdefine y3          rdi + 12*8
    %xdefine z3          rdi + 24*8
    %xdefine x           rsi
    %xdefine y           rsi + 12*8
    %xdefine z           rsi + 24*8
    %xdefine t0          rsp
    %xdefine t1          rsp + 1*384
    %xdefine t2          rsp + 2*384
    %xdefine t3          rsp + 3*384
    %xdefine t4          rsp + 4*384
    %xdefine t5          rsp + 5*384
    %xdefine v11v34      rsp + 6*384
    %xdefine scratch     rsp + 6*384 + 192
    %xdefine stack_size  6*384 + 192 + 768

    ; build stack frame
    push rbp
    mov rbp, rsp
    and rsp, -32
    sub rsp, stack_size

    ; assume forall v in {x, y, z} : |v| ≤ 1.01 * 2^22
    vxorpd xmm15, xmm15, xmm15                      ; [0, 0]
    %assign i 0
    %rep 12
        vbroadcastsd ymm0, qword [x + i*8]          ; [x, x, x, x]
        vbroadcastsd ymm1, qword [y + i*8]          ; [y, y, y, y]
        vbroadcastsd ymm2, qword [z + i*8]          ; [z, z, z, z]
        vblendpd ymm3, ymm0, ymm2, 0b1100           ; [x, x, z, z]
        vblendpd ymm4, ymm0, ymm2, 0b0110           ; [x, z, z, x]
        vblendpd ymm4, ymm4, ymm1, 0b1000           ; [x, z, z, y]
        vmovapd yword [t0 + i*32], ymm3
        vmovapd yword [t1 + i*32], ymm4
        ; prepare for second mul
        vblendpd xmm5, xmm0, xmm1, 0b01             ; [y, x]
        vblendpd xmm6, xmm15, xmm0, 0b10            ; [0, x]
        vaddpd xmm5, xmm5, xmm6                     ; [y, 2*x]

        vmovapd oword [t3 + i*32 + 16], xmm1        ; t3 = [??, ??, y, y]
        vmovapd oword [t4 + i*32 + 16], xmm5        ; t4 = [??, ??, y, 2*x]
    %assign i i+1
    %endrep

    fe12x4_mul t2, t0, t1, scratch                  ; computing [v1, v6, v3, v28] ≤ 1.01 * 2^21

    ; t2 is now in ymm{0-11}
    vmovapd ymm12, [rel .const_mulsmall]
    %assign i 0
    %rep 12
        vpermilpd ymm13, ymm%[i], 0b0010            ; [v1, v6, v3, v3]
        vmulpd ymm%[i], ymm13, ymm12                ; computing [v24, v18, v8, v17]
                                                    ; |v24| ≤ 1.52 * 2^22
                                                    ; |v18| ≤ 1.65 * 2^35
                                                    ; |v8|  ≤ 1.65 * 2^33
                                                    ; |v17| ≤ 1.52 * 2^22
    %assign i i+1
    %endrep

    %assign i 0
    %rep 12
        vextractf128 xmm12, ymm%[i], 0b1            ; [v8, v17]
        vpermilpd xmm13, xmm12, 0b1                 ; [v17, v8]
        vaddsd xmm14, xmm%[i], xmm13                ; computing v25 : |v25| ≤ 1.52 * 2^23
        vpermilpd xmm%[i], xmm%[i], 0b1             ; [v18, v24]
        vaddsd xmm13, xmm%[i], xmm13                ; computing v19 : |v19| ≤ 1.66 * 2^35
        vmovapd xmm15, oword [t2 + i*32]            ; [v1, v6]
        vsubsd xmm13, xmm15, xmm13                  ; computing v20 : |v20| ≤ 1.67 * 2^35
        vmulsd xmm13, xmm13, qword [rel .const_neg3]; computing v22 : |v20| ≤ 1.26 * 2^37
        vunpcklpd xmm13, xmm13, xmm14               ; [v22, v25]
        vpermilpd xmm15, xmm15, 0b1                 ; [v6, v1]
        vaddsd xmm14, xmm12, xmm15                  ; computing v9  : |v9|  ≤ 1.66 * 2^33
        vmulsd xmm14, xmm14, qword [rel .const_neg6]; computing v11 : |v11| ≤ 1.25 * 2^36
        vmovsd xmm12, qword [t2 + 32*i + 24]        ; reload v28
        ; TODO(dsprenkels) Maybe parallelise computation [v11, v34] to save one vmulsd op
        vmulsd xmm12, xmm12, qword [rel .const_8]   ; computing v34 : |v34| ≤ 1.01 * 2^24
        vunpcklpd xmm12, xmm14, xmm12               ; [v11, v34]
        vinsertf128 ymm%[i], ymm12, xmm13, 0b1      ; [v11, v34, v22, v25]

    %assign i i+1
    %endrep

    fe12x4_squeeze_body                             ; squeezing [v11, v34, v22, v25] ≤ 1.01 * 2^21

    %assign i 0
    %rep 12
        vmovapd oword [v11v34 + 16*i], xmm%[i]      ; spill [v11, v34]
        vextractf128 xmm12, ymm%[i], 0b1            ; [v22, v25]
        vmovddup xmm13, xmm12                       ; [v22, v22]
        vmovapd oword [t3 + i*32], xmm13            ; t3 = [v22, v22, y, y]
        vmovsd xmm14, qword [t2 + i*32 + 24]        ; [v28]
        ; TODO(dsprenkels) We can maybe optimise the next op with a blend from 0,t2 and a vaddpd
        vaddsd xmm14, xmm14, xmm14                  ; computing v29a : |v29a| ≤ 1.01 * 2^22
        vblendpd xmm12, xmm12, xmm14, 0b01          ; [v29a, v25]
        vmovapd oword [t4 + i*32], xmm12            ; t4 = [v29a, v25, y, 2*x]

    %assign i i+1
    %endrep

    fe12x4_mul t5, t3, t4, scratch                  ; computing [v30, v26, v2, v5] ≤ 1.01 * 2^21

    ; for the third batched multiplication we'll reuse {t0,t1,t2}
    %assign i 0
    %rep 12
        ; TODO(dsprenkels) Eliminate this load (?):
        vmovapd xmm0, oword [t5 + i*32 + 16]        ; [v2, v5]
        vmovsd xmm1, qword [v11v34 + i*16]          ; v11
        vsubsd xmm2, xmm0, xmm1                     ; computing v12 : |v12| ≤ 1.01 * 2^22
        vaddsd xmm3, xmm0, xmm1                     ; computing v13 : |v13| ≤ 1.01 * 2^22
        vmovapd oword [t0 + 32*i], xmm0             ; t0 = [v2, v5, ??, ??]
        vmovsd qword [t0 + 32*i + 16], xmm2         ; t0 = [v2, v5, v12, ??]
        vmovsd xmm4, qword [v11v34 + i*16 + 8]      ; reload v34
        vmovsd qword [t1 + 32*i], xmm4              ; t1 = [v34, ??, ??, ??]
        vmovsd qword [t1 + 32*i + 8], xmm2          ; t1 = [v34, v12, ??, ??]
        vmovsd qword [t1 + 32*i + 16], xmm3         ; t1 = [v34, v12, v13, ??]
    %assign i i+1
    %endrep

    fe12x4_mul_nosave t2, t0, t1, scratch           ; computing [v32, v15, v14, ??] ≤ 1.01 * 2^21
    %assign i 0
    %rep 12
        vpermilpd xmm12, xmm%[i], 0b1               ; v15
        vextractf128 xmm13, ymm%[i], 0b1            ; v14
        vsubsd xmm12, xmm12, qword [t5 + 32*i]      ; computing v31 : |v31| ≤ 1.01 * 2^22
        vaddsd xmm13, xmm13, qword [t5 + 32*i + 8]  ; computing v27 : |v27| ≤ 1.01 * 2^22
        ; save doubled point
        vmovsd qword [x3 + 8*i], xmm12              ; store x3
        vmovsd qword [y3 + 8*i], xmm13              ; store y3
        vmovsd qword [z3 + 8*i], xmm%[i]            ; store z3
    %assign i i+1
    %endrep

    %pop ge_double_ctx

    ; restore stack frame
    mov rsp, rbp
    pop rbp
    ret

section .rodata
fe12x4_mul_consts
fe12x4_squeeze_consts

align 32,       db 0
.const_mulsmall: dq 3.0, 26636.0, -6659.0, -3.0
align 4,        db 0
.const_neg3:    dq -3.0
.const_neg6:    dq -6.0
.const_8:       dq 8.0
