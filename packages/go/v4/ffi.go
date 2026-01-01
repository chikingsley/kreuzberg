package kreuzberg

/*
#cgo !windows pkg-config: kreuzberg-ffi
#cgo !pkg-config,!windows CFLAGS: -I${SRCDIR}/internal/ffi
#cgo !pkg-config,!windows LDFLAGS: -lkreuzberg_ffi
#cgo windows CFLAGS: -I${SRCDIR}/internal/ffi
#cgo windows LDFLAGS: -lkreuzberg_ffi -lws2_32 -luserenv -lbcrypt

#include "internal/ffi/kreuzberg.h"
#include <stdlib.h>
#include <stdint.h>
*/
import "C"
