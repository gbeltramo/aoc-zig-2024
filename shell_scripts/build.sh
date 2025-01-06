# ===
BUILD_TARGET="x86_64-linux"
# ===
# ZIG_OPTIMIZATION_MODE="Debug"
ZIG_OPTIMIZATION_MODE="ReleaseSafe"
# ZIG_OPTIMIZATION_MODE="ReleaseFast"
# ===

zig build \
    -Dtarget=${BUILD_TARGET} \
    -Doptimize=${ZIG_OPTIMIZATION_MODE} \
    --summary all
