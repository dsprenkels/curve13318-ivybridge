; Multiplication function for field elements (integers modulo 2^255 - 19)
;
; Author: Amber Sprenkels <amber@electricdusk.com>

%include "bench.asm"

section .rodata

_bench1_name: db `select_gcc\0`
_bench2_name: db `select_clang\0`
_bench3_name: db `select_asm_vorpd\0`
_bench4_name: db `select_asm_vaddpd\0`

align 8, db 0
_bench_fns_arr:
dq select_gcc, select_clang, select_asm_vorpd, select_asm_vaddpd

_bench_names_arr:
dq _bench1_name, _bench2_name, _bench3_name, _bench4_name

_bench_fns: dq _bench_fns_arr
_bench_names: dq _bench_names_arr
_bench_fns_n: dd 4

section .bss
align 32
scratch_ptable: resb 4608
scratch_dest: resb 288

section .text

select_gcc:
        bench_prologue
        lea rdi, [rel scratch_dest]
        mov rsi, 0x1F
        lea rdx, [rel scratch_ptable]

        push    rbx
        lea     rcx, [rdi+96]
        lea     r8, [rdi+384]
.L2:
        lea     rax, [rcx-96]
.L3:
        mov     qword [rax], 0x000000000
        add     rax, 8
        cmp     rcx, rax
        jne     .L3
        add     rcx, 96
        cmp     r8, rcx
        jne     .L2
        xor     eax, eax
        cmp     sil, 31
        movzx   ebx, sil
        mov  rcx, 4607182418800017408
        sete    al
        mov     r10, rdx
        lea     r11, [rdi+288]
        neg     rax
        xor     r9d, r9d
        and     rax, rcx
        or      rax, qword [rdi+96]
        mov     qword [rdi+96], rax
.L8:
        xor     r8d, r8d
        cmp     r9d, ebx
        mov     rcx, rdi
        sete    r8b
        mov     rsi, r10
        neg     r8
.L5:
        xor     eax, eax
.L6:
        mov     rdx, qword [rsi+rax]
        and     rdx, r8
        or      rdx, qword [rcx+rax]
        mov     qword [rcx+rax], rdx
        add     rax, 8
        cmp     rax, 96
        jne     .L6
        add     rcx, 96
        add     rsi, 96
        cmp     r11, rcx
        jne     .L5
        add     r9d, 1
        add     r10, 288
        cmp     r9d, 16
        jne     .L8
        pop     rbx

        bench_epilogue
        ret

select_clang:
        bench_prologue
        lea rdi, [rel scratch_dest]
        mov rsi, 0x1F
        lea rdx, [rel scratch_ptable]

        vxorps  xmm0, xmm0, xmm0
        vmovups oword [rdi + 96], xmm0
        vmovups oword [rdi + 16], xmm0
        vmovups oword [rdi], xmm0
        vmovups oword [rdi + 48], xmm0
        vmovups oword [rdi + 32], xmm0
        vmovups oword [rdi + 80], xmm0
        vmovups oword [rdi + 64], xmm0
        vmovups oword [rdi + 112], xmm0
        vmovups oword [rdi + 144], xmm0
        vmovups oword [rdi + 128], xmm0
        vmovups oword [rdi + 176], xmm0
        vmovups oword [rdi + 160], xmm0
        vmovups oword [rdi + 208], xmm0
        vmovups oword [rdi + 192], xmm0
        vmovups oword [rdi + 240], xmm0
        vmovups oword [rdi + 224], xmm0
        vmovups oword [rdi + 272], xmm0
        vmovups oword [rdi + 256], xmm0
        xor     r9d, r9d
        cmp     sil, 31
        mov  rcx, 4607182418800017408
        cmovne  rcx, r9
        mov     qword [rdi + 96], rcx
        mov     r8d, esi
.LBB0_1:
        xor     esi, esi
        cmp     r9, r8
        sete    sil
        neg     rsi
        mov     ecx, 88
.LBB0_2:
        mov     rax, qword [rdx + rcx - 88]
        and     rax, rsi
        or      qword [rdi + rcx - 88], rax
        mov     rax, qword [rdx + rcx - 80]
        and     rax, rsi
        or      qword [rdi + rcx - 80], rax
        mov     rax, qword [rdx + rcx - 72]
        and     rax, rsi
        or      qword [rdi + rcx - 72], rax
        mov     rax, qword [rdx + rcx - 64]
        and     rax, rsi
        or      qword [rdi + rcx - 64], rax
        mov     rax, qword [rdx + rcx - 56]
        and     rax, rsi
        or      qword [rdi + rcx - 56], rax
        mov     rax, qword [rdx + rcx - 48]
        and     rax, rsi
        or      qword [rdi + rcx - 48], rax
        mov     rax, qword [rdx + rcx - 40]
        and     rax, rsi
        or      qword [rdi + rcx - 40], rax
        mov     rax, qword [rdx + rcx - 32]
        and     rax, rsi
        or      qword [rdi + rcx - 32], rax
        mov     rax, qword [rdx + rcx - 24]
        and     rax, rsi
        or      qword [rdi + rcx - 24], rax
        mov     rax, qword [rdx + rcx - 16]
        and     rax, rsi
        or      qword [rdi + rcx - 16], rax
        mov     rax, qword [rdx + rcx - 8]
        and     rax, rsi
        or      qword [rdi + rcx - 8], rax
        mov     rax, qword [rdx + rcx]
        and     rax, rsi
        or      qword [rdi + rcx], rax
        add     rcx, 96
        cmp     rcx, 376
        jne     .LBB0_2
        add     r9, 1
        add     rdx, 288
        cmp     r9, 16
        jne     .LBB0_1

        bench_epilogue
        ret

select_asm_vorpd:
    bench_prologue
    lea rdi, [rel scratch_dest]
    mov rsi, 0x1F
    lea rdx, [rel scratch_ptable]

    ; select the element from the lookup table at index `idx` and copy the
    ; element to `dest`.
    ; C-type: void select(ge dest, uint8_t idx, const ge ptable[16])
    ;
    ; Arguments:
    ;   - rdi: destination buffer
    ;   - sil: idx (unsigned)
    ;   - rdx: pointer to the start of the lookup table
    ;
    ; Anatomy of this routine:
    ; For each scan of the lookup table we will need to do one load and one
    ; vandpd instruction. For borh of these ops, the reciprocal throughput
    ; is 1.0. We will actually need to do *some* more loads, so we will
    ; focus on minimising those.
    ;
    ; We use the following registers as accumulators:
    ;   - {ymm0-ymm2}: X
    ;   - {ymm3-ymm5}: Y
    ;   - {ymm6-ymm8}: Z

    ; conditionally move the first element from ptable (or set to 0)
    xor rax, rax
    test sil, sil
    setz al
    neg rax
    vmovq xmm15, rax
    vmovddup xmm15, xmm15
    vinsertf128 ymm15, xmm15, 0b1
    %assign j 0
    %rep 9
        vandpd ymm%[j], ymm15, yword [rdx + 32*j]
        %assign j j+1
    %endrep

    ; conditionally move the other elements from ptable
    %assign i 1
    %rep 15
        xor rax, rax
        cmp sil, i
        sete al
        neg rax
        vmovq xmm15, rax
        vmovddup xmm15, xmm15
        vinsertf128 ymm15, xmm15, 0b1

        %assign j 0
        %rep 9
            vandpd ymm14, ymm15, yword [rdx + 288*i + 32*j]
            vorpd ymm%[j], ymm%[j], ymm14
            %assign j j+1
        %endrep

        %assign i i+1
    %endrep

    ; conditionally move the neutral element if idx == 31
    xor rax, rax
    mov rcx, [rel .const_1]
    cmp sil, 31
    cmove rax, rcx
    vxorpd ymm15, ymm15, ymm15
    vmovq xmm15, rax
    vorpd ymm3, ymm3, ymm15

    ; writeback the field element
    vmovapd [rdi], ymm0
    vmovapd [rdi + 1*32], ymm1
    vmovapd [rdi + 2*32], ymm2
    vmovapd [rdi + 3*32], ymm3
    vmovapd [rdi + 4*32], ymm4
    vmovapd [rdi + 5*32], ymm5
    vmovapd [rdi + 6*32], ymm6
    vmovapd [rdi + 7*32], ymm7
    vmovapd [rdi + 8*32], ymm8

    bench_epilogue
    ret

section .rodata:
.const_1: dq 1.0

section .text:
select_asm_vaddpd:
    bench_prologue
    lea rdi, [rel scratch_dest]
    mov rsi, 0x1F
    lea rdx, [rel scratch_ptable]

    ; select the element from the lookup table at index `idx` and copy the
    ; element to `dest`.
    ; C-type: void select(ge dest, uint8_t idx, const ge ptable[16])
    ;
    ; Arguments:
    ;   - rdi: destination buffer
    ;   - sil: idx (unsigned)
    ;   - rdx: pointer to the start of the lookup table
    ;
    ; Anatomy of this routine:
    ; For each scan of the lookup table we will need to do one load and one
    ; vandpd instruction. For borh of these ops, the reciprocal throughput
    ; is 1.0. We will actually need to do *some* more loads, so we will
    ; focus on minimising those.
    ;
    ; We use the following registers as accumulators:
    ;   - {ymm0-ymm2}: X
    ;   - {ymm3-ymm5}: Y
    ;   - {ymm6-ymm8}: Z

    ; conditionally move the first element from ptable (or set to 0)
    xor rax, rax
    test sil, sil
    setz al
    neg rax
    vmovq xmm15, rax
    vmovddup xmm15, xmm15
    vinsertf128 ymm15, xmm15, 0b1
    %assign j 0
    %rep 9
        vandpd ymm%[j], ymm15, yword [rdx + 32*j]
        %assign j j+1
    %endrep

    ; conditionally move the other elements from ptable
    %assign i 1
    %rep 15
        xor rax, rax
        cmp sil, i
        sete al
        neg rax
        vmovq xmm15, rax
        vmovddup xmm15, xmm15
        vinsertf128 ymm15, xmm15, 0b1

        %assign j 0
        %rep 9
            vandpd ymm14, ymm15, yword [rdx + 288*i + 32*j]
            vaddpd ymm%[j], ymm%[j], ymm14
            %assign j j+1
        %endrep

        %assign i i+1
    %endrep

    ; conditionally move the neutral element if idx == 31
    xor rax, rax
    mov rcx, [rel .const_1]
    cmp sil, 31
    cmove rax, rcx
    vxorpd ymm15, ymm15, ymm15
    vmovq xmm15, rax
    vorpd ymm3, ymm3, ymm15

    ; writeback the field element
    vmovapd [rdi], ymm0
    vmovapd [rdi + 1*32], ymm1
    vmovapd [rdi + 2*32], ymm2
    vmovapd [rdi + 3*32], ymm3
    vmovapd [rdi + 4*32], ymm4
    vmovapd [rdi + 5*32], ymm5
    vmovapd [rdi + 6*32], ymm6
    vmovapd [rdi + 7*32], ymm7
    vmovapd [rdi + 8*32], ymm8

    bench_epilogue
    ret

.rodata:
.const_1: dq 1.0
