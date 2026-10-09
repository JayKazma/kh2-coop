/* ucrt-only CRT functions the mod uses, for the msvcrt-based MinGW link. */
#include <stdlib.h>
#include <string.h>
#include <errno.h>
int _dupenv_s(char** out, size_t* len, const char* name) {
    *out = NULL; if (len) *len = 0;
    const char* v = getenv(name); if (!v) return 0;
    size_t n = strlen(v) + 1; char* p = (char*)malloc(n); if (!p) return ENOMEM;
    memcpy(p, v, n); *out = p; if (len) *len = n; return 0;
}
