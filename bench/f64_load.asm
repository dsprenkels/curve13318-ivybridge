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
_bench7_name: db `f64_load_16_random\0`
_bench8_name: db `f64_load_16_interleaved\0`
_bench9_name: db `f64_load_16_reverse_interleaved\0`

align 8, db 0
_bench_fns_arr:
dq f64_load_1, f64_load_2, f64_load_4, f64_load_8, f64_load_16, f64_load_160, f64_load_16_random, f64_load16_interleaved, f64_load16_reverse_interleaved

_bench_names_arr:
dq _bench1_name, _bench2_name, _bench3_name, _bench4_name, _bench5_name, _bench6_name, _bench7_name, _bench8_name, _bench9_name

_bench_fns: dq _bench_fns_arr
_bench_names: dq _bench_names_arr
_bench_fns_n: dd 9

section .text:

%macro load16 1
    vmovapd ymm0, yword [rel table+512*%1+0]
    vmovapd ymm1, yword [rel table+512*%1+32]
    vmovapd ymm2, yword [rel table+512*%1+64]
    vmovapd ymm3, yword [rel table+512*%1+96]
    vmovapd ymm4, yword [rel table+512*%1+128]
    vmovapd ymm5, yword [rel table+512*%1+160]
    vmovapd ymm6, yword [rel table+512*%1+192]
    vmovapd ymm7, yword [rel table+512*%1+224]
    vmovapd ymm8, yword [rel table+512*%1+256]
    vmovapd ymm9, yword [rel table+512*%1+288]
    vmovapd ymm10, yword [rel table+512*%1+320]
    vmovapd ymm11, yword [rel table+512*%1+352]
    vmovapd ymm12, yword [rel table+512*%1+384]
    vmovapd ymm13, yword [rel table+512*%1+416]
    vmovapd ymm14, yword [rel table+512*%1+448]
    vmovapd ymm15, yword [rel table+512*%1+480]
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
    vmovapd ymm0, yword [rel table+0]
    vmovapd ymm1, yword [rel table+32]
    vmovapd ymm2, yword [rel table+64]
    vmovapd ymm3, yword [rel table+96]
    vmovapd ymm4, yword [rel table+128]
    vmovapd ymm5, yword [rel table+160]
    vmovapd ymm6, yword [rel table+192]
    vmovapd ymm7, yword [rel table+224]
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

f64_load_16_random:
    bench_prologue
    vmovapd ymm0, yword [rel table+0]
    vmovapd ymm1, yword [rel table+128]
    vmovapd ymm2, yword [rel table+448]
    vmovapd ymm3, yword [rel table+480]
    vmovapd ymm4, yword [rel table+96]
    vmovapd ymm5, yword [rel table+160]
    vmovapd ymm6, yword [rel table+192]
    vmovapd ymm7, yword [rel table+416]
    vmovapd ymm8, yword [rel table+320]
    vmovapd ymm9, yword [rel table+288]
    vmovapd ymm10, yword [rel table+256]
    vmovapd ymm11, yword [rel table+64]
    vmovapd ymm12, yword [rel table+224]
    vmovapd ymm13, yword [rel table+32]
    vmovapd ymm14, yword [rel table+352]
    vmovapd ymm15, yword [rel table+384]
    bench_epilogue
    ret

f64_load16_interleaved:
    bench_prologue
    vmovapd ymm0, yword [rel table+4096*0+0]
    vmovapd ymm1, yword [rel table+4096*1+0]
    vmovapd ymm2, yword [rel table+4096*0+32]
    vmovapd ymm3, yword [rel table+4096*1+32]
    vmovapd ymm4, yword [rel table+4096*0+64]
    vmovapd ymm5, yword [rel table+4096*1+64]
    vmovapd ymm6, yword [rel table+4096*0+96]
    vmovapd ymm7, yword [rel table+4096*1+96]
    vmovapd ymm8, yword [rel table+4096*0+128]
    vmovapd ymm9, yword [rel table+4096*1+128]
    vmovapd ymm10, yword [rel table+4096*0+160]
    vmovapd ymm11, yword [rel table+4096*1+160]
    vmovapd ymm12, yword [rel table+4096*0+192]
    vmovapd ymm13, yword [rel table+4096*1+192]
    vmovapd ymm14, yword [rel table+4096*0+224]
    vmovapd ymm15, yword [rel table+4096*1+224]
    bench_epilogue
    ret

f64_load16_reverse_interleaved:
    bench_prologue
    vmovapd ymm0, yword [rel table+4096*0+0]
    vmovapd ymm1, yword [rel table+4096*1+0]
    vmovapd ymm3, yword [rel table+4096*1+32]
    vmovapd ymm2, yword [rel table+4096*0+32]
    vmovapd ymm4, yword [rel table+4096*0+64]
    vmovapd ymm5, yword [rel table+4096*1+64]
    vmovapd ymm7, yword [rel table+4096*1+96]
    vmovapd ymm6, yword [rel table+4096*0+96]
    vmovapd ymm8, yword [rel table+4096*0+128]
    vmovapd ymm9, yword [rel table+4096*1+128]
    vmovapd ymm11, yword [rel table+4096*1+160]
    vmovapd ymm10, yword [rel table+4096*0+160]
    vmovapd ymm12, yword [rel table+4096*0+192]
    vmovapd ymm13, yword [rel table+4096*1+192]
    vmovapd ymm15, yword [rel table+4096*1+224]
    vmovapd ymm14, yword [rel table+4096*0+224]
    bench_epilogue
    ret

section .rodata:

align 32, db 0
table:
times 200 dq 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0
