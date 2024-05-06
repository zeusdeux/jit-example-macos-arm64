        .global _start
        .align 2

;;; COMPILE and RUN CMD:
;;;   as -o hello.o hello.s && ld -macos_version_min 14.0.0 -o hello.bin hello.o -e _start -arch arm64 && ./hello.bin
;;;
;;; EXTRACT FLAT (PURE) BINARY: (from: https://stackoverflow.com/a/13306947)
;;;   1. otool -l hello.bin | grep -A4 "sectname __text" | tail -1  (offset field is in decimal not hex btw)
;;;    1a. Take the offset, convert to hex and verify code starts there in the hexdump view of the compiled binary
;;;   2. dd if=hello.bin of=hello_flat.bin ibs=<offset> skip=1
;;;
;;;   OR
;;;
;;;   otool -l hello.bin | grep -A4 "sectname __text" | tail -1 | grep -o "\d+" | xargs -n1 -I% dd if=hello.bin of=hello_flat.bin ibs=% skip=1
;;;
;;; syscalls from https://opensource.apple.com/source/xnu/xnu-1504.3.12/bsd/kern/syscalls.master
;;; search for function such as "exit(" for exit syscall or "write(int fd" for write syscall
;;; More here: https://filippo.io/making-system-calls-from-assembly-in-mac-os-x/
;;; And here: https://stackoverflow.com/a/34191324
;;; And here: https://stackoverflow.com/questions/56985859/ios-arm64-syscalls
_start:
        mov x16, #4             ; 4 -> write syscall
        mov x0, #1              ; 1 -> stdout
        adr x1, msg             ; copy relative address of "msg" label into x1 -> https://stackoverflow.com/a/65354324
        mov x2, msg_len              ; length of msg aka "Hello, World!\n"
        svc 0x80                ; syscall SWI_SYSCALL found in /Library/Developer/CommandLineTools/SDKs/MacOSX13.3.sdk/usr/include/mach/arm/vm_param.h and used in /Library/Developer/CommandLineTools/SDKs/MacOSX13.3.sdk/usr/include/mach/arm/syscall_sw.h

        mov x16, #1              ; 1 -> exit syscall
        mov x0, #69              ; exit code is 69
        svc 0x80
        ret

msg:    .ascii "Hello, World from arm64 assembly!\n"
        .equ msg_len, . - msg
