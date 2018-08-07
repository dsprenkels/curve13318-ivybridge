; Compare which is faster, two times vaddpd with operands from memory, or one vmovdqa
; and two vaddpd with register operand.
;
; Author: Amber Sprenkels <amber@electricdusk.com>

%include "bench.asm"

section .rodata:

_bench1_name: db `squeeze_separate_load\0`
_bench2_name: db `squeeze_immediate_load\0`
align 8, db 0
_bench_fns_arr: dq bench_squeeze1, bench_squeeze2,
_bench_names_arr: dq _bench1_name, _bench2_name
_bench_fns: dq _bench_fns_arr
_bench_names: dq _bench_names_arr
_bench_fns_n: dd 2

section .text:

bench_squeeze1:
    bench_prologue

    ; round 1
    vmovapd ymm12, yword [rel long_precisionloss0]
    vmovapd ymm13, yword [rel long_precisionloss6]
    vaddpd ymm14, ymm0, ymm12
    vaddpd ymm15, ymm6, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vaddpd ymm1, ymm1, ymm14
    vaddpd ymm7, ymm7, ymm15
    vsubpd ymm0, ymm0, ymm14
    vsubpd ymm6, ymm6, ymm15

    ; round 2
    vmovapd ymm12, yword [rel long_precisionloss1]
    vmovapd ymm13, yword [rel long_precisionloss7]
    vaddpd ymm14, ymm1, ymm12
    vaddpd ymm15, ymm7, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vaddpd ymm2, ymm2, ymm14
    vaddpd ymm8, ymm8, ymm15
    vsubpd ymm1, ymm1, ymm14
    vsubpd ymm7, ymm7, ymm15

    ; round 3
    vmovapd ymm12, yword [rel long_precisionloss2]
    vmovapd ymm13, yword [rel long_precisionloss8]
    vaddpd ymm14, ymm2, ymm12
    vaddpd ymm15, ymm8, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vaddpd ymm3, ymm3, ymm14
    vaddpd ymm9, ymm9, ymm15
    vsubpd ymm2, ymm2, ymm14
    vsubpd ymm8, ymm8, ymm15

    ; round 4
    vmovapd ymm12, yword [rel long_precisionloss3]
    vmovapd ymm13, yword [rel long_precisionloss9]
    vaddpd ymm14, ymm3, ymm12
    vaddpd ymm15, ymm9, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vaddpd ymm4, ymm4, ymm14
    vaddpd ymm10, ymm10, ymm15
    vsubpd ymm3, ymm3, ymm14
    vsubpd ymm9, ymm9, ymm15

    ; round 5
    vmovapd ymm12, yword [rel long_precisionloss4]
    vmovapd ymm13, yword [rel long_precisionloss10]
    vaddpd ymm14, ymm4, ymm12
    vaddpd ymm15, ymm10, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vaddpd ymm5, ymm5, ymm14
    vaddpd ymm11, ymm11, ymm15
    vsubpd ymm4, ymm4, ymm14
    vsubpd ymm10, ymm10, ymm15

    ; round 6
    vmovapd ymm12, yword [rel long_precisionloss5]
    vmovapd ymm13, yword [rel long_precisionloss11]
    vaddpd ymm14, ymm5, ymm12
    vaddpd ymm15, ymm11, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vsubpd ymm5, ymm5, ymm14
    vsubpd ymm11, ymm11, ymm15
    vmulpd ymm15, ymm15, yword [rel long_reduceconstant]
    vaddpd ymm6, ymm6, ymm14
    vaddpd ymm0, ymm0, ymm15

    ; round 7
    vmovapd ymm12, yword [rel long_precisionloss6]
    vmovapd ymm13, yword [rel long_precisionloss0]
    vaddpd ymm14, ymm6, ymm12
    vaddpd ymm15, ymm0, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vaddpd ymm7, ymm7, ymm14
    vaddpd ymm1, ymm1, ymm15
    vsubpd ymm6, ymm6, ymm14
    vsubpd ymm0, ymm0, ymm15

    ; round 8
    vmovapd ymm12, yword [rel long_precisionloss7]
    vmovapd ymm13, yword [rel long_precisionloss1]
    vaddpd ymm14, ymm7, ymm12
    vaddpd ymm15, ymm1, ymm13
    vsubpd ymm14, ymm14, ymm12
    vsubpd ymm15, ymm15, ymm13
    vaddpd ymm8, ymm8, ymm14
    vaddpd ymm2, ymm2, ymm15
    vsubpd ymm7, ymm7, ymm14
    vsubpd ymm1, ymm1, ymm15

    bench_epilogue
    ret

bench_squeeze2:
    bench_prologue

    ; round 1
    vaddpd ymm14, ymm0, yword [rel long_precisionloss0]
    vaddpd ymm15, ymm6, yword [rel long_precisionloss6]
    vsubpd ymm14, ymm14, yword [rel long_precisionloss0]
    vsubpd ymm15, ymm15, yword [rel long_precisionloss6]
    vaddpd ymm1, ymm1, ymm14
    vaddpd ymm7, ymm7, ymm15
    vsubpd ymm0, ymm0, ymm14
    vsubpd ymm6, ymm6, ymm15

    ; round 2
    vaddpd ymm14, ymm1, yword [rel long_precisionloss1]
    vaddpd ymm15, ymm7, yword [rel long_precisionloss7]
    vsubpd ymm14, ymm14, yword [rel long_precisionloss1]
    vsubpd ymm15, ymm15, yword [rel long_precisionloss7]
    vaddpd ymm2, ymm2, ymm14
    vaddpd ymm8, ymm8, ymm15
    vsubpd ymm1, ymm1, ymm14
    vsubpd ymm7, ymm7, ymm15

    ; round 3
    vaddpd ymm14, ymm2, yword [rel long_precisionloss2]
    vaddpd ymm15, ymm8, yword [rel long_precisionloss8]
    vsubpd ymm14, ymm14, yword [rel long_precisionloss2]
    vsubpd ymm15, ymm15, yword [rel long_precisionloss8]
    vaddpd ymm3, ymm3, ymm14
    vaddpd ymm9, ymm9, ymm15
    vsubpd ymm2, ymm2, ymm14
    vsubpd ymm8, ymm8, ymm15

    ; round 4
    vaddpd ymm14, ymm3, yword [rel long_precisionloss3]
    vaddpd ymm15, ymm9, yword [rel long_precisionloss9]
    vsubpd ymm14, ymm14, yword [rel long_precisionloss3]
    vsubpd ymm15, ymm15, yword [rel long_precisionloss9]
    vaddpd ymm4, ymm4, ymm14
    vaddpd ymm10, ymm10, ymm15
    vsubpd ymm3, ymm3, ymm14
    vsubpd ymm9, ymm9, ymm15

    ; round 5
    vaddpd ymm14, ymm4, yword [rel long_precisionloss4]
    vaddpd ymm15, ymm10, yword [rel long_precisionloss10]
    vsubpd ymm14, ymm14, yword [rel long_precisionloss4]
    vsubpd ymm15, ymm15, yword [rel long_precisionloss10]
    vaddpd ymm5, ymm5, ymm14
    vaddpd ymm11, ymm11, ymm15
    vsubpd ymm4, ymm4, ymm14
    vsubpd ymm10, ymm10, ymm15

    ; round 6
    vaddpd ymm14, ymm5, yword [rel long_precisionloss5]
    vaddpd ymm15, ymm11, yword [rel long_precisionloss11]
    vsubpd ymm14, ymm14, yword [rel long_precisionloss5]
    vsubpd ymm15, ymm15, yword [rel long_precisionloss11]
    vsubpd ymm5, ymm5, ymm14
    vsubpd ymm11, ymm11, ymm15
    vmulpd ymm15, ymm15, yword [rel long_reduceconstant]
    vaddpd ymm6, ymm6, ymm14
    vaddpd ymm0, ymm0, ymm15

    ; round 7
    vaddpd ymm14, ymm6, yword [rel long_precisionloss6]
    vaddpd ymm15, ymm0, yword [rel long_precisionloss0]
    vsubpd ymm14, ymm14, yword [rel long_precisionloss6]
    vsubpd ymm15, ymm15, yword [rel long_precisionloss0]
    vaddpd ymm7, ymm7, ymm14
    vaddpd ymm1, ymm1, ymm15
    vsubpd ymm6, ymm6, ymm14
    vsubpd ymm0, ymm0, ymm15

    ; round 8
    vaddpd ymm14, ymm7, yword [rel long_precisionloss7]
    vaddpd ymm15, ymm1, yword [rel long_precisionloss1]
    vsubpd ymm14, ymm14, yword [rel long_precisionloss7]
    vsubpd ymm15, ymm15, yword [rel long_precisionloss1]
    vaddpd ymm8, ymm8, ymm14
    vaddpd ymm2, ymm2, ymm15
    vsubpd ymm7, ymm7, ymm14
    vsubpd ymm1, ymm1, ymm15

    bench_epilogue
    ret


section .rodata:

align 8, db 0
short_precisionloss0: dq 0x3p73
short_precisionloss1: dq 0x3p94
short_precisionloss2: dq 0x3p115
short_precisionloss3: dq 0x3p136
short_precisionloss4: dq 0x3p158
short_precisionloss5: dq 0x3p179
short_precisionloss6: dq 0x3p200
short_precisionloss7: dq 0x3p221
short_precisionloss8: dq 0x3p243
short_precisionloss9: dq 0x3p264
short_precisionloss10: dq 0x3p285
short_precisionloss11: dq 0x3p306
short_reduceconstant: dq 0x13p-255

align 32, db 0
long_precisionloss0: times 4 dq 0x3p73
long_precisionloss1: times 4 dq 0x3p94
long_precisionloss2: times 4 dq 0x3p115
long_precisionloss3: times 4 dq 0x3p136
long_precisionloss4: times 4 dq 0x3p158
long_precisionloss5: times 4 dq 0x3p179
long_precisionloss6: times 4 dq 0x3p200
long_precisionloss7: times 4 dq 0x3p221
long_precisionloss8: times 4 dq 0x3p243
long_precisionloss9: times 4 dq 0x3p264
long_precisionloss10: times 4 dq 0x3p285
long_precisionloss11: times 4 dq 0x3p306
long_reduceconstant: times 4 dq 0x13p-255
