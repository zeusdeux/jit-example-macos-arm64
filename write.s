        .global _start
        .align 2

_start:
        mov x3, x0              ; save msg received from caller in x3
        mov x4, x1              ; save msg length received from caller in x4
        mov x5, x2              ; save exit code received from caller in x5
        mov x16, #4             ; 4 -> write syscall
        mov x0, #1              ; 1 -> stdout
        mov x1, x3              ; move saved msg received from caller into x1
        mov x2, x4              ; move saved msg length received from caller into x2
        svc 0x80                ; imm value of 0x80 for svc instruction is usually ignored by the processor
                                ; but can be used by the interrupt (exception?) handler in the kernel
                                ; to determine what svc is being requested

        mov x16, #1             ; 1 -> exit syscall
        mov x0, x5              ; move saved exit_code received from caller into x0
        svc 0x80
        ret
