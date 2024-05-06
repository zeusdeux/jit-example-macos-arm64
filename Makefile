hello.o: hello.s
	@as -o hello.o hello.s

hello.bin: hello.o
	@ld -macos_version_min 14.0.0 -o hello.bin hello.o -e _start -arch arm64

hello_flat.bin: hello.bin
	@otool -l hello.bin | grep -A4 "sectname __text" | tail -1 | grep -o "\d+" | xargs -n1 -I% dd if=hello.bin of=hello_flat.bin ibs=% skip=1 2>/dev/null # remove stderr redirect if flat binary isn't executing correctly

jit: hello_flat.bin
	@gcc -g -std=c17 -Wall -Wdeprecated -Wpedantic -Wextra -o ./jit jit.c
	@codesign -s - -f --entitlements jit.entitlements jit 2>/dev/null # remove stderr redirect if `make clean run` doesn't work

entitlements:
	@rm -f ./jit.entitlements && /usr/libexec/PlistBuddy -c "Add :com.apple.security.cs.allow-jit bool true" jit.entitlements

run: jit
	@./jit

clean:
	@$(RM) -fr *.o *.dSYM ./jit *.bin *.o

.PHONY: run clean entitlements
