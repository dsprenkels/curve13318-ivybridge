; Compare which is faster, multiplying a float by 0x1p-128 or setting bit 59 to zero
;
; Author: Amber Sprenkels <amber@electricdusk.com>

%include "bench.asm"

section .rodata:

_bench1_name: db `f64_div128_mul_short\0`
_bench2_name: db `f64_div128_mul_long\0`
_bench3_name: db `f64_div128_and_short\0`
_bench4_name: db `f64_div128_and_long\0`
_bench5_name: db `f64_div128_mixed\0`

align 8, db 0
_bench_fns_arr:
dq f64_div128_mul_short
dq f64_div128_mul_long
dq f64_div128_and_short
dq f64_div128_and_long
dq f64_div128_mixed

_bench_names_arr:
dq _bench1_name, _bench2_name, _bench3_name, _bench4_name, _bench5_name

_bench_fns: dq _bench_fns_arr
_bench_names: dq _bench_names_arr
_bench_fns_n: dd 5

section .text:

f64_div128_mul_short:
    bench_prologue

    vbroadcastsd ymm6, qword [rel shiftright_mul]
    vmulpd ymm0, ymm0, ymm6
    vmulpd ymm1, ymm1, ymm6
    vmulpd ymm2, ymm2, ymm6
    vmulpd ymm3, ymm3, ymm6
    vmulpd ymm4, ymm4, ymm6
    vmulpd ymm5, ymm5, ymm6

    vmulpd ymm0, ymm0, ymm6
    vmulpd ymm1, ymm1, ymm6
    vmulpd ymm2, ymm2, ymm6
    vmulpd ymm3, ymm3, ymm6
    vmulpd ymm4, ymm4, ymm6
    vmulpd ymm5, ymm5, ymm6

    bench_epilogue
    ret

f64_div128_mul_long:
    bench_prologue

    vmulpd ymm0, ymm0, yword [rel shiftright_mul]
    vmulpd ymm1, ymm1, yword [rel shiftright_mul]
    vmulpd ymm2, ymm2, yword [rel shiftright_mul]
    vmulpd ymm3, ymm3, yword [rel shiftright_mul]
    vmulpd ymm4, ymm4, yword [rel shiftright_mul]
    vmulpd ymm5, ymm5, yword [rel shiftright_mul]

    vmulpd ymm0, ymm0, yword [rel shiftright_mul]
    vmulpd ymm1, ymm1, yword [rel shiftright_mul]
    vmulpd ymm2, ymm2, yword [rel shiftright_mul]
    vmulpd ymm3, ymm3, yword [rel shiftright_mul]
    vmulpd ymm4, ymm4, yword [rel shiftright_mul]
    vmulpd ymm5, ymm5, yword [rel shiftright_mul]

    bench_epilogue
    ret


f64_div128_and_short:
    bench_prologue

    vbroadcastsd ymm6, qword [rel shiftright_and]
    vandpd ymm0, ymm0, ymm6
    vandpd ymm1, ymm1, ymm6
    vandpd ymm2, ymm2, ymm6
    vandpd ymm3, ymm3, ymm6
    vandpd ymm4, ymm4, ymm6
    vandpd ymm5, ymm5, ymm6

    vandpd ymm0, ymm0, ymm6
    vandpd ymm1, ymm1, ymm6
    vandpd ymm2, ymm2, ymm6
    vandpd ymm3, ymm3, ymm6
    vandpd ymm4, ymm4, ymm6
    vandpd ymm5, ymm5, ymm6

    bench_epilogue
    ret

f64_div128_and_long:
    bench_prologue

    vandpd ymm0, ymm0, yword [rel shiftright_and]
    vandpd ymm1, ymm1, yword [rel shiftright_and]
    vandpd ymm2, ymm2, yword [rel shiftright_and]
    vandpd ymm3, ymm3, yword [rel shiftright_and]
    vandpd ymm4, ymm4, yword [rel shiftright_and]
    vandpd ymm5, ymm5, yword [rel shiftright_and]

    vandpd ymm0, ymm0, yword [rel shiftright_and]
    vandpd ymm1, ymm1, yword [rel shiftright_and]
    vandpd ymm2, ymm2, yword [rel shiftright_and]
    vandpd ymm3, ymm3, yword [rel shiftright_and]
    vandpd ymm4, ymm4, yword [rel shiftright_and]
    vandpd ymm5, ymm5, yword [rel shiftright_and]

    bench_epilogue
    ret

f64_div128_mixed:
    bench_prologue

    vbroadcastsd ymm6, qword [rel shiftright_and]
    vmulpd ymm1, ymm1, yword [rel shiftright_and]
    vmulpd ymm3, ymm3, yword [rel shiftright_and]
    vmulpd ymm5, ymm5, yword [rel shiftright_and]
    vandpd ymm0, ymm0, ymm6
    vandpd ymm2, ymm2, ymm6
    vandpd ymm4, ymm4, ymm6

    vmulpd ymm1, ymm1, yword [rel shiftright_and]
    vmulpd ymm3, ymm3, yword [rel shiftright_and]
    vmulpd ymm5, ymm5, yword [rel shiftright_and]
    vandpd ymm0, ymm0, ymm6
    vandpd ymm2, ymm2, ymm6
    vandpd ymm4, ymm4, ymm6

    bench_epilogue
    ret


section .rodata:

align 8, db 0
shiftright_mul: dq 0x1p-128, 0x1p-128, 0x1p-128, 0x1p-128
shiftright_and: dq 0xF7FFFFFFFFFFFFFF, 0xF7FFFFFFFFFFFFFF, 0xF7FFFFFFFFFFFFFF, 0xF7FFFFFFFFFFFFFF
