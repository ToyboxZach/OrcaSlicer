#include "libslic3r/libslic3r.h"
#ifndef SLIC3R_HEADLESS // The headless core already provides the NanoSVG implementation.
#define NANOSVG_IMPLEMENTATION
#endif
#include "nanosvg/nanosvg.h"
#define NANOSVGRAST_IMPLEMENTATION
#include "nanosvg/nanosvgrast.h"
