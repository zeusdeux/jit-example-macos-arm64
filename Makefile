hello.o: hello.s
	@as -o hello.o hello.s

write.o: write.s
	@as -o write.o write.s

hello.bin: hello.o
	@ld -macos_version_min 14.0.0 -o hello.bin hello.o -e _start -arch arm64

write.bin: write.o
	@ld -macos_version_min 14.0.0 -o write.bin write.o -e _start -arch arm64

hello_flat.bin: hello.bin
	@otool -l hello.bin | grep -A4 "sectname __text" | tail -1 | grep -o "\d+" | xargs -n1 -I% dd if=hello.bin of=hello_flat.bin ibs=% skip=1 2>/dev/null # remove stderr redirect if flat binary isn't executing correctly

write_flat.bin: write.bin
	@otool -l write.bin | grep -A4 "sectname __text" | tail -1 | grep -o "\d+" | xargs -n1 -I% dd if=write.bin of=write_flat.bin ibs=% skip=1 2>/dev/null # remove stderr redirect if flat binary isn't executing correctly

jit: hello_flat.bin write_flat.bin
	@gcc -g -std=c17 -Wall -Wdeprecated -Wpedantic -Wextra -o ./jit jit.c
	@codesign -s - -f --entitlements jit.entitlements jit 2>/dev/null # remove stderr redirect if `make clean run` doesn't work

run: jit
	./jit ./hello_flat.bin
	@echo

	./jit ./write_flat.bin "Message from shell invocation to C program to assembly routine :)" 69
	@echo

clean:
	@$(RM) -fr *.o *.dSYM ./jit *.bin *.o

entitlements:
	@rm -f ./jit.entitlements && /usr/libexec/PlistBuddy -c "Add :com.apple.security.cs.allow-jit bool true" jit.entitlements

.PHONY: run clean entitlements
