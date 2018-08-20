; Multiplication function for field elements (integers modulo 2^255 - 19)
;
; Author: Amber Sprenkels <amber@electricdusk.com>

%include "bench.asm"
%include "fe12_mul.mac"

extern crypto_scalarmult_curve13318_ref12_fe12x4_mul,
extern crypto_scalarmult_curve13318_ref12_fe12x4_squeeze
extern crypto_scalarmult_curve13318_ref12_fe12x4_squeeze_noload
extern crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba
extern crypto_scalarmult_curve13318_ref12_fe12_square_karatsuba
extern crypto_scalarmult_curve13318_ref12_fe12_squeeze

section .rodata

_bench1_name: db `ge_double_asm\0`
_bench2_name: db `ge_double_gcc\0`
_bench3_name: db `ge_double_clang\0`
_bench4_name: db `ge_double_asm_v2\0`

align 8, db 0
_bench_fns_arr:
dq ge_double_asm, ge_double_gcc, ge_double_clang, ge_double_asm_v2

_bench_names_arr:
dq _bench1_name, _bench2_name, _bench3_name, _bench4_name

_bench_fns: dq _bench_fns_arr
_bench_names: dq _bench_names_arr
_bench_fns_n: dd 4

section .bss
align 32
scratch_space: resb 1536

section .text

ge_double_asm:
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
    bench_prologue

    %push ge_double_ctx
    %define x3          rel scratch_space
    %define y3          rel scratch_space + 12*8
    %define z3          rel scratch_space + 24*8
    %define x           rel scratch_space + 36*8
    %define y           rel scratch_space + 48*8
    %define z           rel scratch_space + 60*8
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

    bench_epilogue
    ret

section .rodata
.const_neg3:    dq -3.0
.const_neg6:    dq -6.0
.const_2:       dq 2.0
.const_8:       dq 8.0
align 32,       db 0
.const_mulsmall: dq 3.0, 26636.0, -6659.0, -3.0

ge_double_asm_v2:
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
    bench_prologue

    %push ge_double_ctx
    %xdefine x3          rel scratch_space
    %xdefine y3          rel scratch_space + 12*8
    %xdefine z3          rel scratch_space + 24*8
    %xdefine x           rel scratch_space + 36*8
    %xdefine y           rel scratch_space + 48*8
    %xdefine z           rel scratch_space + 60*8
    %xdefine t0          rsp
    %xdefine t1          rsp + 1*384
    %xdefine t2          rsp + 2*384
    %xdefine t3          rsp + 3*384
    %xdefine t4          rsp + 4*384
    %xdefine t5          rsp + 5*384
    %xdefine v11         rsp + 6*384
    %xdefine v34         rsp + 6*384 + 1*96
    %xdefine v26v30      rsp + 6*384 + 2*96
    %xdefine old_rdi     rsp + 7*384
    %xdefine scratch     rsp + 7*384 + 32
    %xdefine stack_size  7*384 + 32 + 768

    ; build stack frame
    push rbp
    mov rbp, rsp
    and rsp, -32
    sub rsp, stack_size
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

    fe12x4_mul t2, t0, t1, scratch

    ; t2 is now in ymm{0-11}
    vmovapd ymm12, [rel .const_mulsmall]
    %assign i 0
    %rep 12
        vpermilpd ymm13, ymm%[i], 0b0010    ; [v1, v6, v3, v3]
        vmulpd ymm%[i], ymm13, ymm12        ; computing [v24, v18, v8, v17]
        %assign i i+1
    %endrep
    fe12x4_squeeze_body
    %assign i 0
    %rep 12
        vextractf128 xmm12, ymm%[i], 0b1            ; [v8, v17]
        vpermilpd xmm13, xmm12, 0b1                 ; [v17, v8]
        vaddsd xmm14, xmm%[i], xmm13                ; computing v25
        vmovsd qword [t4 + i*32 + 16], xmm14        ; t4 = [y, x, v25, ??]
        vpermilpd xmm%[i], xmm%[i], 0b1             ; [v18, v24]
        vaddsd xmm13, xmm%[i], xmm13                ; computing v19
        vmovapd xmm14, oword [t2 + i*32]            ; [v1, v6]
        vsubsd xmm13, xmm14, xmm13                  ; computing v20
        vmulsd xmm13, xmm13, [rel .const_neg3]      ; computing v22
        vmovsd qword [t3 + i*32 + 16], xmm13        ; t3 = [y, y, v22, ??]
        vmovsd qword [t3 + i*32 + 24], xmm13        ; t3 = [y, y, v22, v22]
        vpermilpd xmm14, xmm14, 0b1                 ; [v6, v1]
        vaddsd xmm12, xmm12, xmm14                  ; computing v9
        vmulsd xmm12, xmm12, [rel .const_neg6]      ; computing v11
        vmovsd qword [v11 + 8*i], xmm12             ; spill v11

        ; put r29 in t4
        vmovsd xmm12, qword [t2 + i*32 + 24]        ; [v28]
        vmulsd xmm13, xmm12, qword [rel .const_2]   ; computing v29a
        vmovsd qword [t4 + i*32 + 24], xmm13        ; t4 = [y, x, v25, v29a]
        vmulsd xmm12, xmm12, qword [rel .const_8]   ; computing v34
        vmovsd qword [v34 + i*8], xmm12             ; spill v34
        %assign i i+1
    %endrep

    fe12x4_squeeze t0
    fe12x4_squeeze t1
    fe12x4_mul t5, t3, t4, scratch

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
        vmovapd oword [v26v30 + 16*i], xmm7     ; spill [v26, v30]
    %assign i i+1
    %endrep

    fe12x4_squeeze t0
    fe12x4_squeeze t1
    fe12x4_mul t2, t0, t1, scratch

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
    bench_epilogue
    ret

section .rodata
.const_neg3:    dq -3.0
.const_neg6:    dq -6.0
.const_2:       dq 2.0
.const_8:       dq 8.0
align 32,       db 0
.const_mulsmall: dq 3.0, 26636.0, -6659.0, -3.0
fe12x4_mul_consts
fe12x4_squeeze_consts

section .text

ge_double_gcc:
        bench_prologue
        push    r12
        xor     eax, eax
        lea     r12, [rel scratch_space]
        push    rbp
        push    rbx
        sub     rsp, 960
.L2:
        vmovsd  xmm0, [r12+36*8+rax]
        vmovsd  [rsp+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L2
        xor     eax, eax
.L3:
        vmovsd  xmm0, [r12+36*8+96+rax]
        vmovsd  [rsp+96+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L3
        xor     eax, eax
.L4:
        vmovsd  xmm0, [r12+36*8+192+rax]
        vmovsd  [rsp+192+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L4
        lea     rdi, [rsp+576]
        mov     rsi, rsp
        call    crypto_scalarmult_curve13318_ref12_fe12_square_karatsuba wrt ..plt
        lea     rsi, [rsp+96]
        lea     rdi, [rsp+672]
        call    crypto_scalarmult_curve13318_ref12_fe12_square_karatsuba wrt ..plt
        lea     rsi, [rsp+192]
        lea     rdi, [rsp+768]
        call    crypto_scalarmult_curve13318_ref12_fe12_square_karatsuba wrt ..plt
        lea     rdx, [rsp+96]
        mov     rsi, rsp
        lea     rdi, [rsp+864]
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        lea     rax, [rsp+864]
        lea     rdx, [rsp+960]
.L5:
        vmovsd  xmm0, [rax]
        add     rax, 8
        vaddsd  xmm0, xmm0, xmm0
        vmovsd  [rax-8], xmm0
        cmp     rdx, rax
        jne     .L5
        lea     rdi, [rsp+768]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rdi, [rsp+864]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rbx, [rsp+480]
        mov     rsi, rsp
        lea     rdx, [rsp+192]
        lea     rdi, [rsp+480]
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        lea     rbp, [rbx+96]
        mov     rax, rbx
.L6:
        vmovsd  xmm0, [rax]
        add     rax, 8
        vaddsd  xmm0, xmm0, xmm0
        vmovsd  [rax-8], xmm0
        cmp     rbp, rax
        jne     .L6
        xor     eax, eax
.L7:
        vmovsd  xmm0, [rsp+768+rax]
        vmovsd  [rsp+384+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L7
        lea     rax, [rsp+384]
        vmovsd  xmm1, [rel .LC0]
        lea     rdx, [rax+96]
.L8:
        vmulsd  xmm0, xmm1, [rax]
        add     rax, 8
        vmovsd  [rax-8], xmm0
        cmp     rdx, rax
        jne     .L8
        xor     eax, eax
.L9:
        vmovsd  xmm0, [rsp+384+rax]
        vsubsd  xmm0, xmm0, [rsp+480+rax]
        vmovsd  [rsp+384+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L9
        xor     eax, eax
.L10:
        vmovsd  xmm0, [rsp+384+rax]
        vaddsd  xmm0, xmm0, xmm0
        vmovsd  [rsp+288+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L10
        xor     eax, eax
.L11:
        vmovsd  xmm0, [rsp+288+rax]
        vaddsd  xmm0, xmm0, [rsp+384+rax]
        vmovsd  [rsp+384+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L11
        xor     eax, eax
.L12:
        vmovsd  xmm0, [rsp+672+rax]
        vsubsd  xmm0, xmm0, [rsp+384+rax]
        vmovsd  [rsp+288+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L12
        xor     eax, eax
.L13:
        vmovsd  xmm0, [rsp+672+rax]
        vaddsd  xmm0, xmm0, [rsp+384+rax]
        vmovsd  [rsp+384+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L13
        lea     rdi, [rsp+288]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rdi, [rsp+384]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rdi, [rsp+480]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rdx, [rsp+384]
        lea     rsi, [rsp+288]
        mov     rdi, rdx
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        lea     rsi, [rsp+288]
        lea     rdx, [rsp+864]
        mov     rdi, rsi
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        mov     rcx, [rel .LC0]
        xor     eax, eax
        vmovq   xmm1, rcx
.L14:
        vmovsd  xmm0, [rsp+768+rax]
        vaddsd  xmm0, xmm0, xmm0
        vmovsd  [rsp+864+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L14
        xor     eax, eax
.L15:
        vmovsd  xmm0, [rsp+768+rax]
        vaddsd  xmm0, xmm0, [rsp+864+rax]
        vmovsd  [rsp+768+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L15
        lea     rax, [rsp+480]
.L16:
        vmulsd  xmm0, xmm1, [rax]
        add     rax, 8
        vmovsd  [rax-8], xmm0
        cmp     rbp, rax
        jne     .L16
        xor     eax, eax
.L17:
        vmovsd  xmm0, [rsp+480+rax]
        vsubsd  xmm0, xmm0, [rsp+768+rax]
        vmovsd  [rsp+480+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L17
        xor     eax, eax
.L18:
        vmovsd  xmm0, [rsp+480+rax]
        vsubsd  xmm0, xmm0, [rsp+576+rax]
        vmovsd  [rsp+480+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L18
        xor     eax, eax
.L19:
        vmovsd  xmm0, [rsp+480+rax]
        vaddsd  xmm0, xmm0, xmm0
        vmovsd  [rsp+864+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L19
        xor     eax, eax
.L20:
        vmovsd  xmm0, [rsp+480+rax]
        vaddsd  xmm0, xmm0, [rsp+864+rax]
        vmovsd  [rsp+480+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L20
        xor     eax, eax
.L21:
        vmovsd  xmm0, [rsp+576+rax]
        vaddsd  xmm0, xmm0, xmm0
        vmovsd  [rsp+864+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L21
        xor     eax, eax
.L22:
        vmovsd  xmm0, [rsp+864+rax]
        vaddsd  xmm0, xmm0, [rsp+576+rax]
        vmovsd  [rsp+576+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L22
        xor     eax, eax
.L23:
        vmovsd  xmm0, [rsp+576+rax]
        vsubsd  xmm0, xmm0, [rsp+768+rax]
        vmovsd  [rsp+576+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L23
        lea     rdi, [rsp+576]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rdi, [rsp+480]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rsi, [rsp+576]
        lea     rdx, [rsp+480]
        mov     rdi, rsi
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        xor     eax, eax
.L24:
        vmovsd  xmm0, [rsp+384+rax]
        vaddsd  xmm0, xmm0, [rsp+576+rax]
        vmovsd  [rsp+384+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L24
        lea     rdx, [rsp+192]
        lea     rsi, [rsp+96]
        lea     rdi, [rsp+576]
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        lea     rax, [rsp+576]
        lea     rdx, [rax+96]
.L25:
        vmovsd  xmm0, [rax]
        add     rax, 8
        vaddsd  xmm0, xmm0, xmm0
        vmovsd  [rax-8], xmm0
        cmp     rdx, rax
        jne     .L25
        lea     rdi, [rsp+576]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rdx, [rsp+480]
        lea     rsi, [rsp+576]
        mov     rdi, rdx
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        xor     eax, eax
.L26:
        vmovsd  xmm0, [rsp+288+rax]
        vsubsd  xmm0, xmm0, [rsp+480+rax]
        vmovsd  [rsp+288+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L26
        lea     rdi, [rsp+576]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rdi, [rsp+672]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rdx, [rsp+672]
        lea     rsi, [rsp+576]
        lea     rdi, [rsp+480]
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        lea     rax, [rsp+480]
.L27:
        vmovsd  xmm0, [rax]
        add     rax, 8
        vaddsd  xmm0, xmm0, xmm0
        vmovsd  [rax-8], xmm0
        cmp     rbp, rax
        jne     .L27
.L28:
        vmovsd  xmm0, [rbx]
        add     rbx, 8
        vaddsd  xmm0, xmm0, xmm0
        vmovsd  [rbx-8], xmm0
        cmp     rbp, rbx
        jne     .L28
        lea     rdi, [rsp+288]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rdi, [rsp+384]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rdi, [rsp+480]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        xor     eax, eax
.L29:
        vmovsd  xmm0, [rsp+288+rax]
        vmovsd  [r12+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L29
        xor     eax, eax
.L30:
        vmovsd  xmm0, [rsp+384+rax]
        vmovsd  [r12+96+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L30
        xor     eax, eax
.L31:
        vmovsd  xmm0, [rsp+480+rax]
        vmovsd  [r12+192+rax], xmm0
        add     rax, 8
        cmp     rax, 96
        jne     .L31
        add     rsp, 960
        pop     rbx
        pop     rbp
        pop     r12
        bench_epilogue
        ret

section .rodata

.LC0:
        dq   0
        dq   1086980864

section .text

ge_double_clang:
        bench_prologue
        push    rbp
        push    r15
        push    r14
        push    r13
        push    r12
        push    rbx
        sub     rsp, 968
        lea     rbx, [rel scratch_space]
        vmovups xmm0, [rel scratch_space + 36*8]
        vmovups xmm1, [rel scratch_space + 36*8 + 16]
        vmovups [rsp + 880], xmm1
        vmovups [rsp + 864], xmm0
        vmovups xmm0, [rel scratch_space + 36*8 + 32]
        vmovups xmm1, [rel scratch_space + 36*8 + 48]
        vmovups [rsp + 912], xmm1
        vmovups [rsp + 896], xmm0
        vmovups xmm0, [rel scratch_space + 36*8 + 64]
        vmovups xmm1, [rel scratch_space + 36*8 + 80]
        vmovups [rsp + 944], xmm1
        vmovups [rsp + 928], xmm0
        vmovups xmm0, [rel scratch_space + 36*8 + 96]
        vmovups xmm1, [rel scratch_space + 36*8 + 112]
        vmovups [rsp + 784], xmm1
        vmovups [rsp + 768], xmm0
        vmovups xmm0, [rel scratch_space + 36*8 + 128]
        vmovups xmm1, [rel scratch_space + 36*8 + 144]
        vmovups [rsp + 816], xmm1
        vmovups [rsp + 800], xmm0
        vmovups xmm0, [rel scratch_space + 36*8 + 160]
        vmovups xmm1, [rel scratch_space + 36*8 + 176]
        vmovups [rsp + 848], xmm1
        vmovups [rsp + 832], xmm0
        vmovups xmm0, [rel scratch_space + 36*8 + 192]
        vmovups xmm1, [rel scratch_space + 36*8 + 208]
        vmovups [rsp + 688], xmm1
        vmovups [rsp + 672], xmm0
        vmovups xmm0, [rel scratch_space + 36*8 + 224]
        vmovups xmm1, [rel scratch_space + 36*8 + 240]
        vmovups [rsp + 720], xmm1
        vmovups [rsp + 704], xmm0
        vmovups xmm0, [rel scratch_space + 36*8 + 256]
        vmovups xmm1, [rel scratch_space + 36*8 + 272]
        vmovups [rsp + 752], xmm1
        vmovups [rsp + 736], xmm0
        lea     rdi, [rsp + 96]
        lea     r15, [rsp + 864]
        mov     rsi, r15
        call    crypto_scalarmult_curve13318_ref12_fe12_square_karatsuba wrt ..plt
        lea     rdi, [rsp + 576]
        lea     rbp, [rsp + 768]
        mov     rsi, rbp
        call    crypto_scalarmult_curve13318_ref12_fe12_square_karatsuba wrt ..plt
        lea     r12, [rsp + 480]
        lea     r14, [rsp + 672]
        mov     rdi, r12
        mov     rsi, r14
        call    crypto_scalarmult_curve13318_ref12_fe12_square_karatsuba wrt ..plt
        lea     r13, [rsp + 192]
        mov     rdi, r13
        mov     rsi, r15
        mov     rdx, rbp
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        vmovups xmm0, [rsp + 192]
        vmovups xmm1, [rsp + 224]
        vmovups xmm2, [rsp + 256]
        vinsertf128     ymm0, ymm0, [rsp + 208], 1
        vaddpd  ymm0, ymm0, ymm0
        vextractf128    [rsp + 208], ymm0, 1
        vmovupd [rsp + 192], xmm0
        vinsertf128     ymm0, ymm1, [rsp + 240], 1
        vaddpd  ymm0, ymm0, ymm0
        vextractf128    [rsp + 240], ymm0, 1
        vmovupd [rsp + 224], xmm0
        vinsertf128     ymm0, ymm2, [rsp + 272], 1
        vaddpd  ymm0, ymm0, ymm0
        vextractf128    [rsp + 272], ymm0, 1
        vmovupd [rsp + 256], xmm0
        mov     rdi, r12
        vzeroupper
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        mov     rdi, r13
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        mov     r12, rsp
        mov     rdi, r12
        mov     rsi, r15
        mov     rdx, r14
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        vmovups xmm0, [rsp]
        vmovups xmm1, [rsp + 32]
        vmovups xmm2, [rsp + 64]
        vinsertf128     ymm0, ymm0, [rsp + 16], 1
        vaddpd  ymm0, ymm0, ymm0
        vextractf128    [rsp + 16], ymm0, 1
        vmovupd [rsp], xmm0
        vinsertf128     ymm1, ymm1, [rsp + 48], 1
        vaddpd  ymm1, ymm1, ymm1
        vextractf128    [rsp + 48], ymm1, 1
        vmovupd [rsp + 32], xmm1
        vinsertf128     ymm2, ymm2, [rsp + 80], 1
        vaddpd  ymm2, ymm2, ymm2
        vextractf128    [rsp + 80], ymm2, 1
        vmovupd [rsp + 64], xmm2
        vmovups xmm3, [rsp + 480]
        vmovups xmm4, [rsp + 512]
        vmovups xmm5, [rsp + 544]
        vinsertf128     ymm3, ymm3, [rsp + 496], 1
        vinsertf128     ymm4, ymm4, [rsp + 528], 1
        vinsertf128     ymm5, ymm5, [rsp + 560], 1
        vmovupd ymm6, yword [rel .LCPI0_0]
        vmulpd  ymm3, ymm3, ymm6
        vmulpd  ymm4, ymm4, ymm6
        vmulpd  ymm5, ymm5, ymm6
        vsubpd  ymm0, ymm3, ymm0
        vsubpd  ymm1, ymm4, ymm1
        vsubpd  ymm2, ymm5, ymm2
        vaddpd  ymm3, ymm0, ymm0
        vaddpd  ymm4, ymm1, ymm1
        vaddpd  ymm5, ymm2, ymm2
        vaddpd  ymm0, ymm0, ymm3
        vaddpd  ymm1, ymm1, ymm4
        vaddpd  ymm2, ymm2, ymm5
        vmovups xmm3, [rsp + 576]
        vmovups xmm4, [rsp + 608]
        vmovups xmm5, [rsp + 640]
        vinsertf128     ymm3, ymm3, [rsp + 592], 1
        vsubpd  ymm6, ymm3, ymm0
        vextractf128    [rsp + 400], ymm6, 1
        vmovupd [rsp + 384], xmm6
        vinsertf128     ymm4, ymm4, [rsp + 624], 1
        vsubpd  ymm6, ymm4, ymm1
        vextractf128    [rsp + 432], ymm6, 1
        vmovupd [rsp + 416], xmm6
        vinsertf128     ymm5, ymm5, [rsp + 656], 1
        vsubpd  ymm6, ymm5, ymm2
        vextractf128    [rsp + 464], ymm6, 1
        vmovupd [rsp + 448], xmm6
        vaddpd  ymm0, ymm0, ymm3
        vextractf128    [rsp + 304], ymm0, 1
        vmovupd [rsp + 288], xmm0
        vaddpd  ymm0, ymm1, ymm4
        vextractf128    [rsp + 336], ymm0, 1
        vmovupd [rsp + 320], xmm0
        vaddpd  ymm0, ymm2, ymm5
        vextractf128    [rsp + 368], ymm0, 1
        vmovupd [rsp + 352], xmm0
        lea     r15, [rsp + 384]
        mov     rdi, r15
        vzeroupper
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rbp, [rsp + 288]
        mov     rdi, rbp
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        mov     rdi, r12
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        mov     rdi, rbp
        mov     rsi, r15
        mov     rdx, rbp
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        mov     rdi, r15
        mov     rsi, r15
        mov     rdx, r13
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        vmovupd xmm0, [rsp + 480]
        vmovupd xmm1, [rsp + 496]
        vmovupd xmm10, [rsp + 512]
        vmovupd xmm11, [rsp + 528]
        vaddpd  xmm4, xmm0, xmm0
        vmovupd [rsp + 192], xmm4
        vaddpd  xmm5, xmm1, xmm1
        vmovupd [rsp + 208], xmm5
        vaddpd  xmm6, xmm10, xmm10
        vmovupd [rsp + 224], xmm6
        vaddpd  xmm7, xmm11, xmm11
        vmovupd [rsp + 240], xmm7
        vmovupd xmm8, [rsp + 544]
        vaddpd  xmm9, xmm8, xmm8
        vmovupd [rsp + 256], xmm9
        vmovupd xmm2, [rsp + 560]
        vaddpd  xmm3, xmm2, xmm2
        vmovupd [rsp + 272], xmm3
        vinsertf128     ymm0, ymm0, xmm1, 1
        vinsertf128     ymm1, ymm4, xmm5, 1
        vaddpd  ymm12, ymm0, ymm1
        vextractf128    [rsp + 496], ymm12, 1
        vmovupd [rsp + 480], xmm12
        vinsertf128     ymm1, ymm10, xmm11, 1
        vinsertf128     ymm4, ymm6, xmm7, 1
        vaddpd  ymm1, ymm1, ymm4
        vextractf128    [rsp + 528], ymm1, 1
        vmovupd [rsp + 512], xmm1
        vinsertf128     ymm2, ymm8, xmm2, 1
        vinsertf128     ymm3, ymm9, xmm3, 1
        vaddpd  ymm2, ymm2, ymm3
        vextractf128    [rsp + 560], ymm2, 1
        vmovupd [rsp + 544], xmm2
        vmovups xmm3, [rsp]
        vmovups xmm4, [rsp + 32]
        vmovups xmm5, [rsp + 64]
        vinsertf128     ymm3, ymm3, [rsp + 16], 1
        vinsertf128     ymm4, ymm4, [rsp + 48], 1
        vinsertf128     ymm5, ymm5, [rsp + 80], 1
        vmovupd ymm0, yword [rel .LCPI0_0]
        vmulpd  ymm3, ymm3, ymm0
        vmulpd  ymm4, ymm4, ymm0
        vmulpd  ymm5, ymm5, ymm0
        vsubpd  ymm7, ymm3, ymm12
        vsubpd  ymm8, ymm4, ymm1
        vsubpd  ymm9, ymm5, ymm2
        vmovupd xmm10, [rsp + 96]
        vmovupd xmm0, [rsp + 112]
        vmovups xmm4, [rsp + 128]
        vmovupd xmm6, [rsp + 160]
        vinsertf128     ymm11, ymm10, xmm0, 1
        vsubpd  ymm7, ymm7, ymm11
        vinsertf128     ymm4, ymm4, [rsp + 144], 1
        vsubpd  ymm8, ymm8, ymm4
        vmovupd xmm3, [rsp + 176]
        vinsertf128     ymm5, ymm6, xmm3, 1
        vsubpd  ymm9, ymm9, ymm5
        vaddpd  ymm13, ymm7, ymm7
        vaddpd  ymm14, ymm8, ymm8
        vaddpd  ymm15, ymm9, ymm9
        vaddpd  ymm7, ymm7, ymm13
        vextractf128    [rsp + 16], ymm7, 1
        vmovupd [rsp], xmm7
        vaddpd  ymm7, ymm8, ymm14
        vextractf128    [rsp + 48], ymm7, 1
        vmovupd [rsp + 32], xmm7
        vaddpd  ymm7, ymm9, ymm15
        vextractf128    [rsp + 80], ymm7, 1
        vmovupd [rsp + 64], xmm7
        vaddpd  xmm9, xmm10, xmm10
        vmovupd [rsp + 192], xmm9
        vaddpd  xmm0, xmm0, xmm0
        vmovupd [rsp + 208], xmm0
        vaddpd  ymm8, ymm4, ymm4
        vmovlpd qword [rsp + 224], xmm8
        vmovhpd qword [rsp + 232], xmm8
        vextractf128    xmm7, ymm8, 1
        vmovlpd qword [rsp + 240], xmm7
        vmovhpd qword [rsp + 248], xmm7
        vaddpd  xmm6, xmm6, xmm6
        vmovupd [rsp + 256], xmm6
        vaddpd  xmm3, xmm3, xmm3
        vmovupd [rsp + 272], xmm3
        vinsertf128     ymm0, ymm9, xmm0, 1
        vaddpd  ymm0, ymm11, ymm0
        vaddpd  ymm4, ymm4, ymm8
        vinsertf128     ymm3, ymm6, xmm3, 1
        vaddpd  ymm3, ymm5, ymm3
        vsubpd  ymm0, ymm0, ymm12
        vextractf128    [rsp + 112], ymm0, 1
        vmovupd [rsp + 96], xmm0
        vsubpd  ymm0, ymm4, ymm1
        vextractf128    [rsp + 144], ymm0, 1
        vmovupd [rsp + 128], xmm0
        vsubpd  ymm0, ymm3, ymm2
        vextractf128    [rsp + 176], ymm0, 1
        vmovupd [rsp + 160], xmm0
        lea     r14, [rsp + 96]
        mov     rdi, r14
        vzeroupper
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        mov     rdi, r12
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        mov     rdi, r14
        mov     rsi, r14
        mov     rdx, r12
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        vmovups xmm0, [rsp + 288]
        vmovups xmm1, [rsp + 320]
        vinsertf128     ymm0, ymm0, [rsp + 304], 1
        vmovups xmm2, [rsp + 352]
        vmovups xmm3, [rsp + 96]
        vinsertf128     ymm3, ymm3, [rsp + 112], 1
        vmovups xmm4, [rsp + 128]
        vaddpd  ymm0, ymm0, ymm3
        vextractf128    [rsp + 304], ymm0, 1
        vmovupd [rsp + 288], xmm0
        vinsertf128     ymm0, ymm1, [rsp + 336], 1
        vinsertf128     ymm1, ymm4, [rsp + 144], 1
        vmovups xmm3, [rsp + 160]
        vaddpd  ymm0, ymm0, ymm1
        vextractf128    [rsp + 336], ymm0, 1
        vmovupd [rsp + 320], xmm0
        vinsertf128     ymm0, ymm2, [rsp + 368], 1
        vinsertf128     ymm1, ymm3, [rsp + 176], 1
        vaddpd  ymm0, ymm0, ymm1
        vextractf128    [rsp + 368], ymm0, 1
        vmovupd [rsp + 352], xmm0
        mov     rdi, r14
        lea     rsi, [rsp + 768]
        lea     rdx, [rsp + 672]
        vzeroupper
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        vmovups xmm0, [rsp + 96]
        vmovups xmm1, [rsp + 128]
        vmovups xmm2, [rsp + 160]
        vinsertf128     ymm0, ymm0, [rsp + 112], 1
        vaddpd  ymm0, ymm0, ymm0
        vextractf128    [rsp + 112], ymm0, 1
        vmovupd [rsp + 96], xmm0
        vinsertf128     ymm0, ymm1, [rsp + 144], 1
        vaddpd  ymm0, ymm0, ymm0
        vextractf128    [rsp + 144], ymm0, 1
        vmovupd [rsp + 128], xmm0
        vinsertf128     ymm0, ymm2, [rsp + 176], 1
        vaddpd  ymm0, ymm0, ymm0
        vextractf128    [rsp + 176], ymm0, 1
        vmovupd [rsp + 160], xmm0
        mov     rdi, r14
        vzeroupper
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        mov     rdi, r12
        mov     rsi, r14
        mov     rdx, r12
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        vmovups xmm0, [rsp + 384]
        vmovups xmm1, [rsp + 416]
        vinsertf128     ymm0, ymm0, [rsp + 400], 1
        vmovups xmm2, [rsp + 448]
        vmovups xmm3, [rsp]
        vinsertf128     ymm3, ymm3, [rsp + 16], 1
        vmovups xmm4, [rsp + 32]
        vsubpd  ymm0, ymm0, ymm3
        vextractf128    [rsp + 400], ymm0, 1
        vmovupd [rsp + 384], xmm0
        vinsertf128     ymm0, ymm1, [rsp + 432], 1
        vinsertf128     ymm1, ymm4, [rsp + 48], 1
        vmovups xmm3, [rsp + 64]
        vsubpd  ymm0, ymm0, ymm1
        vextractf128    [rsp + 432], ymm0, 1
        vmovupd [rsp + 416], xmm0
        vinsertf128     ymm0, ymm2, [rsp + 464], 1
        vinsertf128     ymm1, ymm3, [rsp + 80], 1
        vsubpd  ymm0, ymm0, ymm1
        vextractf128    [rsp + 464], ymm0, 1
        vmovupd [rsp + 448], xmm0
        mov     rdi, r14
        vzeroupper
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rbp, [rsp + 576]
        mov     rdi, rbp
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        mov     rdi, r12
        mov     rsi, r14
        mov     rdx, rbp
        call    crypto_scalarmult_curve13318_ref12_fe12_mul_karatsuba wrt ..plt
        vmovups xmm0, [rsp]
        vinsertf128     ymm0, ymm0, [rsp + 16], 1
        vaddpd  ymm0, ymm0, ymm0
        vmovsd  xmm1, qword [rsp + 32]
        vaddsd  xmm1, xmm1, xmm1
        vmovsd  xmm2, qword [rsp + 40]
        vaddsd  xmm2, xmm2, xmm2
        vmovsd  xmm3, qword [rsp + 48]
        vaddsd  xmm3, xmm3, xmm3
        vmovsd  xmm4, qword [rsp + 56]
        vmovups xmm5, [rsp + 64]
        vinsertf128     ymm5, ymm5, [rsp + 80], 1
        vaddsd  xmm4, xmm4, xmm4
        vaddpd  ymm5, ymm5, ymm5
        vaddpd  ymm0, ymm0, ymm0
        vextractf128    [rsp + 16], ymm0, 1
        vmovupd [rsp], xmm0
        vaddsd  xmm0, xmm1, xmm1
        vmovsd  qword [rsp + 32], xmm0
        vaddsd  xmm0, xmm2, xmm2
        vmovsd  qword [rsp + 40], xmm0
        vaddsd  xmm0, xmm3, xmm3
        vmovsd  qword [rsp + 48], xmm0
        vaddsd  xmm0, xmm4, xmm4
        vmovsd  qword [rsp + 56], xmm0
        vaddpd  ymm0, ymm5, ymm5
        vextractf128    [rsp + 80], ymm0, 1
        vmovupd [rsp + 64], xmm0
        mov     rdi, r15
        vzeroupper
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        lea     rdi, [rsp + 288]
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        mov     rdi, r12
        call    crypto_scalarmult_curve13318_ref12_fe12_squeeze wrt ..plt
        vmovups xmm0, [rsp + 384]
        vmovups xmm1, [rsp + 400]
        vmovups [rbx + 16], xmm1
        vmovups [rbx], xmm0
        vmovups xmm0, [rsp + 416]
        vmovups xmm1, [rsp + 432]
        vmovups [rbx + 48], xmm1
        vmovups [rbx + 32], xmm0
        vmovups xmm0, [rsp + 448]
        vmovups xmm1, [rsp + 464]
        vmovups [rbx + 80], xmm1
        vmovups [rbx + 64], xmm0
        vmovups xmm0, [rsp + 288]
        vmovups xmm1, [rsp + 304]
        vmovups [rbx + 112], xmm1
        vmovups [rbx + 96], xmm0
        vmovups xmm0, [rsp + 320]
        vmovups xmm1, [rsp + 336]
        vmovups [rbx + 144], xmm1
        vmovups [rbx + 128], xmm0
        vmovups xmm0, [rsp + 352]
        vmovups xmm1, [rsp + 368]
        vmovups [rbx + 176], xmm1
        vmovups [rbx + 160], xmm0
        vmovups xmm0, [rsp]
        vmovups xmm1, [rsp + 16]
        vmovups [rbx + 208], xmm1
        vmovups [rbx + 192], xmm0
        vmovups xmm0, [rsp + 32]
        vmovups xmm1, [rsp + 48]
        vmovups [rbx + 240], xmm1
        vmovups [rbx + 224], xmm0
        vmovups xmm0, [rsp + 64]
        vmovups xmm1, [rsp + 80]
        vmovups [rbx + 272], xmm1
        vmovups [rbx + 256], xmm0
        add     rsp, 968
        pop     rbx
        pop     r12
        pop     r13
        pop     r14
        pop     r15
        pop     rbp
        bench_epilogue
        ret

section .rodata

align 32, db 0
.LCPI0_0:
dq   4668547262257823744
dq   4668547262257823744
dq   4668547262257823744
dq   4668547262257823744
