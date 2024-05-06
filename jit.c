#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>
#include <pthread.h>
#include <libkern/OSCacheControl.h>

#include "./zdx_util.h"
#define ZDX_FILE_IMPLEMENTATION
#include "./zdx_file.h"

typedef void(*code_t)(void);

int main(void)
{
  const char *file_path = "./hello_flat.bin";

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
  ((code_t)code)();

  fc_deinit(&fc);

  return 0;
}
