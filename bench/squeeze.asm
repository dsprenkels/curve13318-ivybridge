; Compare which is faster, two times vaddpd with operands from memory, or one vmovdqa
; and two vaddpd with register operand.
;
; Author: Amber Sprenkels <amber@electricdusk.com>

%include "bench.asm"

section .rodata:

_bench1_name: db `squeeze_separate_load\0`
_bench2_name: db `squeeze_immediate_load\0`
_bench3_name: db `squeeze_noparallel\0`
_bench4_name: db `carry_sandy2x\0`
align 8, db 0
_bench_fns_arr: dq bench_squeeze1, bench_squeeze2, bench_squeeze3, bench_carry_sandy2x
_bench_names_arr: dq _bench1_name, _bench2_name, _bench3_name, _bench4_name
_bench_fns: dq _bench_fns_arr
_bench_names: dq _bench_names_arr
_bench_fns_n: dd 4

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

bench_squeeze3:
    bench_prologue

    ; round 1
    vmovapd ymm14, yword [rel long_precisionloss0]
    vaddpd ymm15, ymm0, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm1, ymm1, ymm15
    vsubpd ymm0, ymm0, ymm15
    vmovapd ymm14, yword [rel long_precisionloss6]
    vaddpd ymm15, ymm6, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm7, ymm7, ymm15
    vsubpd ymm6, ymm6, ymm15

    ; round 2
    vmovapd ymm14, yword [rel long_precisionloss1]
    vaddpd ymm15, ymm1, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm2, ymm2, ymm15
    vsubpd ymm1, ymm1, ymm15
    vmovapd ymm14, yword [rel long_precisionloss7]
    vaddpd ymm15, ymm7, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm8, ymm8, ymm15
    vsubpd ymm7, ymm7, ymm15

    ; round 3
    vmovapd ymm14, yword [rel long_precisionloss2]
    vaddpd ymm15, ymm2, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm3, ymm3, ymm15
    vsubpd ymm2, ymm2, ymm15
    vmovapd ymm14, yword [rel long_precisionloss8]
    vaddpd ymm15, ymm8, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm9, ymm9, ymm15
    vsubpd ymm8, ymm8, ymm15

    ; round 4
    vmovapd ymm14, yword [rel long_precisionloss3]
    vaddpd ymm15, ymm3, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm4, ymm4, ymm15
    vsubpd ymm3, ymm3, ymm15
    vmovapd ymm14, yword [rel long_precisionloss9]
    vaddpd ymm15, ymm9, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm10, ymm10, ymm15
    vsubpd ymm9, ymm9, ymm15

    ; round 5
    vmovapd ymm14, yword [rel long_precisionloss4]
    vaddpd ymm15, ymm4, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm5, ymm5, ymm15
    vsubpd ymm4, ymm4, ymm15
    vmovapd ymm14, yword [rel long_precisionloss10]
    vaddpd ymm15, ymm10, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm11, ymm11, ymm15
    vsubpd ymm10, ymm10, ymm15

    ; round 6
    vmovapd ymm14, yword [rel long_precisionloss5]
    vaddpd ymm15, ymm5, ymm14
    vsubpd ymm15, ymm15, ymm14
    vsubpd ymm5, ymm5, ymm15
    vaddpd ymm6, ymm6, ymm15
    vmovapd ymm14, yword [rel long_precisionloss11]
    vaddpd ymm15, ymm11, ymm14
    vsubpd ymm15, ymm15, ymm14
    vsubpd ymm11, ymm11, ymm15
    vmulpd ymm15, ymm15, yword [rel long_reduceconstant]
    vaddpd ymm0, ymm0, ymm15

    ; round 7
    vmovapd ymm14, yword [rel long_precisionloss6]
    vaddpd ymm15, ymm6, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm7, ymm7, ymm15
    vsubpd ymm6, ymm6, ymm15
    vmovapd ymm14, yword [rel long_precisionloss0]
    vaddpd ymm15, ymm0, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm1, ymm1, ymm15
    vsubpd ymm0, ymm0, ymm15

    ; round 8
    vmovapd ymm14, yword [rel long_precisionloss7]
    vaddpd ymm14, ymm7, ymm14
    vsubpd ymm14, ymm14, ymm14
    vaddpd ymm8, ymm8, ymm14
    vsubpd ymm7, ymm7, ymm14
    vmovapd ymm14, yword [rel long_precisionloss1]
    vaddpd ymm15, ymm1, ymm14
    vsubpd ymm15, ymm15, ymm14
    vaddpd ymm2, ymm2, ymm15
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

section .text:

bench_carry_sandy2x:
    bench_prologue

    ; qhasm: 2x carry5 = h5 unsigned>>= 25
    ; asm 1: vpsrlq $25,<h5=reg128#5,>carry5=reg128#4
    ; asm 2: vpsrlq $25,<h5=%xmm4,>carry5=%xmm3
    vpsrlq xmm3, xmm4, 25

    ; qhasm: 2x h6 += carry5
    ; asm 1: paddq <carry5=reg128#4,<h6=reg128#7
    ; asm 2: paddq <carry5=%xmm3,<h6=%xmm6
    paddq xmm6, xmm3

    ; qhasm: h5 &= mem128[ m25 ]
    ; asm 1: pand m25,<h5=reg128#5
    ; asm 2: pand m25,<h5=%xmm4
    pand xmm4, [rel m25]

    ; qhasm: 2x carry0 = h0 unsigned>>= 26
    ; asm 1: vpsrlq $26,<h0=reg128#12,>carry0=reg128#4
    ; asm 2: vpsrlq $26,<h0=%xmm11,>carry0=%xmm3
    vpsrlq xmm3, xmm11, 26

    ; qhasm: 2x h1 += carry0
    ; asm 1: paddq <carry0=reg128#4,<h1=reg128#14
    ; asm 2: paddq <carry0=%xmm3,<h1=%xmm13
    paddq xmm13, xmm3

    ; qhasm: h0 &= mem128[ m26 ]
    ; asm 1: pand m26,<h0=reg128#12
    ; asm 2: pand m26,<h0=%xmm11
    pand xmm11, [rel m26]

    ; qhasm: 2x carry6 = h6 unsigned>>= 26
    ; asm 1: vpsrlq $26,<h6=reg128#7,>carry6=reg128#4
    ; asm 2: vpsrlq $26,<h6=%xmm6,>carry6=%xmm3
    vpsrlq xmm3, xmm6, 26

    ; qhasm: 2x h7 += carry6
    ; asm 1: paddq <carry6=reg128#4,<h7=reg128#6
    ; asm 2: paddq <carry6=%xmm3,<h7=%xmm5
    paddq xmm5, xmm3

    ; qhasm: h6 &= mem128[ m26 ]
    ; asm 1: pand m26,<h6=reg128#7
    ; asm 2: pand m26,<h6=%xmm6
    pand xmm6, [rel m26]

    ; qhasm: 2x carry1 = h1 unsigned>>= 25
    ; asm 1: vpsrlq $25,<h1=reg128#14,>carry1=reg128#4
    ; asm 2: vpsrlq $25,<h1=%xmm13,>carry1=%xmm3
    vpsrlq xmm3, xmm13, 25

    ; qhasm: 2x h2 += carry1
    ; asm 1: paddq <carry1=reg128#4,<h2=reg128#1
    ; asm 2: paddq <carry1=%xmm3,<h2=%xmm0
    paddq xmm0, xmm3

    ; qhasm: h1 &= mem128[ m25 ]
    ; asm 1: pand m25,<h1=reg128#14
    ; asm 2: pand m25,<h1=%xmm13
    pand xmm13, [rel m25]

    ; qhasm: 2x carry7 = h7 unsigned>>= 25
    ; asm 1: vpsrlq $25,<h7=reg128#6,>carry7=reg128#4
    ; asm 2: vpsrlq $25,<h7=%xmm5,>carry7=%xmm3
    vpsrlq xmm3, xmm5, 25

    ; qhasm: 2x h8 += carry7
    ; asm 1: paddq <carry7=reg128#4,<h8=reg128#9
    ; asm 2: paddq <carry7=%xmm3,<h8=%xmm8
    paddq xmm8, xmm3

    ; qhasm: h7 &= mem128[ m25 ]
    ; asm 1: pand m25,<h7=reg128#6
    ; asm 2: pand m25,<h7=%xmm5
    pand xmm5, [rel m25]

    ; qhasm: 2x carry2 = h2 unsigned>>= 26
    ; asm 1: vpsrlq $26,<h2=reg128#1,>carry2=reg128#4
    ; asm 2: vpsrlq $26,<h2=%xmm0,>carry2=%xmm3
    vpsrlq xmm3, xmm0, 26

    ; qhasm: 2x h3 += carry2
    ; asm 1: paddq <carry2=reg128#4,<h3=reg128#3
    ; asm 2: paddq <carry2=%xmm3,<h3=%xmm2
    paddq xmm2, xmm3

    ; qhasm: h2 &= mem128[ m26 ]
    ; asm 1: pand m26,<h2=reg128#1
    ; asm 2: pand m26,<h2=%xmm0
    pand xmm0, [rel m26]

    ; qhasm: 2x carry8 = h8 unsigned>>= 26
    ; asm 1: vpsrlq $26,<h8=reg128#9,>carry8=reg128#4
    ; asm 2: vpsrlq $26,<h8=%xmm8,>carry8=%xmm3
    vpsrlq xmm3, xmm8, 26

    ; qhasm: 2x h9 += carry8
    ; asm 1: paddq <carry8=reg128#4,<h9=reg128#8
    ; asm 2: paddq <carry8=%xmm3,<h9=%xmm7
    paddq xmm7, xmm3

    ; qhasm: h8 &= mem128[ m26 ]
    ; asm 1: pand m26,<h8=reg128#9
    ; asm 2: pand m26,<h8=%xmm8
    pand xmm8, [rel m26]

    ; qhasm: 2x carry3 = h3 unsigned>>= 25
    ; asm 1: vpsrlq $25,<h3=reg128#3,>carry3=reg128#4
    ; asm 2: vpsrlq $25,<h3=%xmm2,>carry3=%xmm3
    vpsrlq xmm3, xmm2, 25

    ; qhasm: 2x h4 += carry3
    ; asm 1: paddq <carry3=reg128#4,<h4=reg128#2
    ; asm 2: paddq <carry3=%xmm3,<h4=%xmm1
    paddq xmm1, xmm3

    ; qhasm: h3 &= mem128[ m25 ]
    ; asm 1: pand m25,<h3=reg128#3
    ; asm 2: pand m25,<h3=%xmm2
    pand xmm2, [rel m25]

    ; qhasm: 2x carry9 = h9 unsigned>>= 25
    ; asm 1: vpsrlq $25,<h9=reg128#8,>carry9=reg128#4
    ; asm 2: vpsrlq $25,<h9=%xmm7,>carry9=%xmm3
    vpsrlq xmm3, xmm7, 25

    ; qhasm: 2x r0 = carry9 << 4
    ; asm 1: vpsllq $4,<carry9=reg128#4,>r0=reg128#10
    ; asm 2: vpsllq $4,<carry9=%xmm3,>r0=%xmm9
    vpsllq xmm9, xmm3, 4

    ; qhasm: 2x h0 += carry9
    ; asm 1: paddq <carry9=reg128#4,<h0=reg128#12
    ; asm 2: paddq <carry9=%xmm3,<h0=%xmm11
    paddq xmm11, xmm3

    ; qhasm: 2x carry9 <<= 1
    ; asm 1: psllq $1,<carry9=reg128#4
    ; asm 2: psllq $1,<carry9=%xmm3
    psllq xmm3, 1

    ; qhasm: 2x r0 += carry9
    ; asm 1: paddq <carry9=reg128#4,<r0=reg128#10
    ; asm 2: paddq <carry9=%xmm3,<r0=%xmm9
    paddq xmm9, xmm3

    ; qhasm: 2x h0 += r0
    ; asm 1: paddq <r0=reg128#10,<h0=reg128#12
    ; asm 2: paddq <r0=%xmm9,<h0=%xmm11
    paddq xmm11, xmm9

    ; qhasm: h9 &= mem128[ m25 ]
    ; asm 1: pand m25,<h9=reg128#8
    ; asm 2: pand m25,<h9=%xmm7
    pand xmm7, [rel m25]

    ; qhasm: 2x carry4 = h4 unsigned>>= 26
    ; asm 1: vpsrlq $26,<h4=reg128#2,>carry4=reg128#4
    ; asm 2: vpsrlq $26,<h4=%xmm1,>carry4=%xmm3
    vpsrlq xmm3, xmm1, 26

    ; qhasm: 2x h5 += carry4
    ; asm 1: paddq <carry4=reg128#4,<h5=reg128#5
    ; asm 2: paddq <carry4=%xmm3,<h5=%xmm4
    paddq xmm4, xmm3

    ; qhasm: h4 &= mem128[ m26 ]
    ; asm 1: pand m26,<h4=reg128#2
    ; asm 2: pand m26,<h4=%xmm1
    pand xmm1, [rel m26]

    ; qhasm: 2x carry0 = h0 unsigned>>= 26
    ; asm 1: vpsrlq $26,<h0=reg128#12,>carry0=reg128#4
    ; asm 2: vpsrlq $26,<h0=%xmm11,>carry0=%xmm3
    vpsrlq xmm3, xmm11, 26

    ; qhasm: 2x h1 += carry0
    ; asm 1: paddq <carry0=reg128#4,<h1=reg128#14
    ; asm 2: paddq <carry0=%xmm3,<h1=%xmm13
    paddq xmm13, xmm3

    ; qhasm: h0 &= mem128[ m26 ]
    ; asm 1: pand m26,<h0=reg128#12
    ; asm 2: pand m26,<h0=%xmm11
    pand xmm11, [rel m26]

    ; qhasm: 2x carry5 = h5 unsigned>>= 25
    ; asm 1: vpsrlq $25,<h5=reg128#5,>carry5=reg128#4
    ; asm 2: vpsrlq $25,<h5=%xmm4,>carry5=%xmm3
    vpsrlq xmm3, xmm4, 25

    ; qhasm: 2x h6 += carry5
    ; asm 1: paddq <carry5=reg128#4,<h6=reg128#7
    ; asm 2: paddq <carry5=%xmm3,<h6=%xmm6
    paddq xmm6, xmm3

    ; qhasm: h5 &= mem128[ m25 ]
    ; asm 1: pand m25,<h5=reg128#5
    ; asm 2: pand m25,<h5=%xmm4
    pand xmm4, [rel m25]

    bench_epilogue
    ret

section .rodata:

align 4, db 0
m25: dq 33554431, 33554431
m26: dq 67108863, 67108863
