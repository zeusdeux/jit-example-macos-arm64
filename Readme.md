# jit-example-macos-arm64

Playing around with some JIT-ting (using `mmap`) on macOS with Apple Silicon (tested on M1 MBP running Sonoma 14.3.1).

To execute, `make clean run`.

> Output:<br>
> ./jit ./hello_flat.bin<br>
> Hello, world from arm64 assembly!<br>
> <br>
> ./jit ./write_flat.bin "Message from shell invocation to C program to assembly routine :)" 69<br>
> Message from shell invocation to C program to assembly routine :)<br>
> make: *** [run] Error 69<br>

If the entitlements are missing, run `make entitlements`
