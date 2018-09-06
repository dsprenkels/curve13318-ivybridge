; Multiplication function for field elements (integers modulo 2^255 - 19)
;
; Author: Amber Sprenkels <amber@electricdusk.com>

%include "bench.asm"

section .rodata

_bench1_name: db `select_gcc\0`
_bench2_name: db `select_clang\0`

align 8, db 0
_bench_fns_arr:
dq select_gcc, select_clang

_bench_names_arr:
dq _bench1_name, _bench2_name

_bench_fns: dq _bench_fns_arr
_bench_names: dq _bench_names_arr
_bench_fns_n: dd 2

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
