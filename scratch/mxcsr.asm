; Helper functions for setting and restoring the MxCsr register
;
; Author: Amber Sprenkels <amber@electricdusk.com>

global crypto_scalarmult_curve13318_ref12_replace_mxcsr
global crypto_scalarmult_curve13318_ref12_restore_mxcsr

crypto_scalarmult_curve13318_ref12_replace_mxcsr:
    stmxcsr dword [rsp-4]
    mov eax, dword [rsp-4]
    mov dword [rsp-4], 0x1f80
    ldmxcsr dword [rsp-4]
    ret

crypto_scalarmult_curve13318_ref12_restore_mxcsr:
    stmxcsr dword [rsp-4]
    ldmxcsr dword [rdi]
    mov eax, [rsp-4]
    and eax, 0xFFFFFFDF
    cmp eax, 0x1f80
    sete al
    ret
