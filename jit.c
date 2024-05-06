#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>
#include <pthread.h>
#include <libkern/OSCacheControl.h>

#include "./zdx_util.h"
#define ZDX_FILE_IMPLEMENTATION
#include "./zdx_file.h"

typedef void(*hello_t)(void);
typedef void(*write_t)(const char *msg, const size_t len, const int8_t exit_code);

int main(int argc, char **argv)
{
  if (argc < 2) {
    log(L_ERROR, "Usage:\n\t jit <path to flat binary>");
    return 1;
  }

  const char *file_path = argv[1];
  const bool is_write_bin = strstr(file_path, "write") != NULL;

  // we expect the msg and exit code in argv as well when running ./write_flat.bin
  if (is_write_bin && argc < 4) {
    log(L_ERROR, "Usage:\n\t jit ./write_flat.bin <msg> <exit code>");
    return 1;
  }

  fl_content_t fc = fl_read_file_str(file_path, "rb");

  if (!fc.is_valid) {
    log(L_ERROR, "Reading flat binary failed: %s", fc.err_msg);
    return 1;
  }

  void *code = mmap(NULL, fc.size, PROT_EXEC | PROT_WRITE, MAP_ANONYMOUS | MAP_PRIVATE | MAP_JIT, -1, 0);

  if (code == MAP_FAILED) {
    log(L_ERROR, "Loading code into memory failed: %s", strerror(errno));
    return 1;
  }

#if 0
  for (size_t i = 0; i < fc.size; i += 2) {
    printf("%zu,%zu = %0.2X%0.2X\n", i, i+1, ((char *)fc.contents)[i] & 0x000000FF, ((char *)fc.contents)[i + 1] & 0x000000FF);
  }
#endif

  // FROM: https://medium.com/@gamedev0909/jit-in-c-injecting-machine-code-at-runtime-1463402e6242
  // allow memcpy-ing raw instruction bytes into mmap-ed region (aka allow writes to it)
  pthread_jit_write_protect_np(0);

  // copy instructions to mmap-ed PROT_EXEC region
  memcpy(code, fc.contents, fc.size);

  // lock down mmap-ed region again (aka disallow writes to it)
  pthread_jit_write_protect_np(1);

  // invalidate the memory page so that instruction caches are coherent with newly written data into mmap-ed region
  // https://developer.apple.com/documentation/apple-silicon/porting-just-in-time-compilers-to-apple-silicon?language=objc
  sys_icache_invalidate(code, fc.size);

  // execute loaded instructions!
  if (is_write_bin) {
    const char *msg = argv[2];
    const size_t msg_len = strlen(msg) + 1; // + 1 for \0
    char final_msg[msg_len + 1]; // + 1 for \n and not + 2 as we already have space for \0 from above
                                 //
    strlcpy(final_msg, msg, msg_len); // copy input string until \0
    strlcat(final_msg, "\n", msg_len + 1); // append \n at the end of input string + \0

    const int8_t exit_code = atoi(argv[3]);

    ((write_t)code)(final_msg, strlen(final_msg), exit_code);
  } else {
    ((hello_t)code)();
  }

  fc_deinit(&fc);

  return 0;
}
