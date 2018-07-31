; Find out how long it takes to load a bunch of values from l1 cache
;
; Author: Amber Sprenkels <amber@electricdusk.com>

%include "bench.asm"

section .rodata:

_bench1_name: db `f64_load_1\0`
_bench2_name: db `f64_load_2\0`
_bench3_name: db `f64_load_4\0`
_bench4_name: db `f64_load_8\0`
_bench5_name: db `f64_load_16\0`
_bench6_name: db `f64_load_160\0`

align 8, db 0
_bench_fns_arr:
dq f64_load_1, f64_load_2, f64_load_4, f64_load_8, f64_load_16, f64_load_160

_bench_names_arr:
dq _bench1_name, _bench2_name, _bench3_name, _bench4_name, _bench5_name, _bench6_name

_bench_fns: dq _bench_fns_arr
_bench_names: dq _bench_names_arr
_bench_fns_n: dd 6

section .text:

%macro load16 1
    vmovapd ymm0, yword [rel table+480*%1+0]
    vmovapd ymm1, yword [rel table+480*%1+32]
    vmovapd ymm2, yword [rel table+480*%1+64]
    vmovapd ymm3, yword [rel table+480*%1+96]
    vmovapd ymm4, yword [rel table+480*%1+128]
    vmovapd ymm5, yword [rel table+480*%1+160]
    vmovapd ymm6, yword [rel table+480*%1+192]
    vmovapd ymm7, yword [rel table+480*%1+224]
    vmovapd ymm8, yword [rel table+480*%1+256]
    vmovapd ymm9, yword [rel table+480*%1+288]
    vmovapd ymm10, yword [rel table+480*%1+320]
    vmovapd ymm11, yword [rel table+480*%1+352]
    vmovapd ymm12, yword [rel table+480*%1+384]
    vmovapd ymm13, yword [rel table+480*%1+416]
    vmovapd ymm14, yword [rel table+480*%1+448]
    vmovapd ymm15, yword [rel table+480*%1+480]
%endmacro

f64_load_1:
    bench_prologue
    vmovapd ymm0, yword [rel table+0]
    bench_epilogue
    ret

f64_load_2:
    bench_prologue
    vmovapd ymm0, yword [rel table+0]
    vmovapd ymm1, yword [rel table+32]
    bench_epilogue
    ret

f64_load_4:
    bench_prologue
    vmovapd ymm0, yword [rel table+0]
    vmovapd ymm1, yword [rel table+32]
    vmovapd ymm2, yword [rel table+64]
    vmovapd ymm3, yword [rel table+96]
    bench_epilogue
    ret

f64_load_8:
    bench_prologue
    vmovapd ymm0, yword [rel table+480+0]
    vmovapd ymm1, yword [rel table+480+32]
    vmovapd ymm2, yword [rel table+480+64]
    vmovapd ymm3, yword [rel table+480+96]
    vmovapd ymm4, yword [rel table+480+128]
    vmovapd ymm5, yword [rel table+480+160]
    vmovapd ymm6, yword [rel table+480+192]
    vmovapd ymm7, yword [rel table+480+224]
    bench_epilogue
    ret

f64_load_16:
    bench_prologue
    load16 0
    bench_epilogue
    ret

f64_load_160:
    bench_prologue
%assign i 0
%rep 10
    load16 i
%assign i i+1
%endrep
    bench_epilogue
    ret


section .rodata:

align 32, db 0
table:
times 20 dq 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0
