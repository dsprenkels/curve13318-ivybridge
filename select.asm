; Select an element from a lookup table
;
; Author: Amber Sprenkels <amber@electricdusk.com>

global crypto_scalarmult_curve13318_ref12_select

section .text
crypto_scalarmult_curve13318_ref12_select:
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

    ; set the destination registers to zero.
    vzeroall

    ; conditionally move the neutral element if idx == 31
    xor rax, rax
    mov rcx, [rel .const_1]
    cmp sil, 31
    cmove rax, rcx
    vmovq xmm3, rax

    ; conditionally move the elements from ptable
    %assign i 0
    %rep 16
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
    ret

.rodata:
.const_1: dq 1.0
