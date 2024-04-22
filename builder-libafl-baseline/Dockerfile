FROM base-clang:latest

RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh \
  git clone git@github.com:tizianocolagrossi/Enumetric.git /src/Enumetric

RUN --mount=type=ssh \
  git clone git@github.com:tizianocolagrossi/LibAFL.git /src/LibAFL

COPY checkout_build_enumetric.sh /root/
# # Keep all steps in the same script to decrease the number of intermediate
# # layes in docker file.
RUN /root/checkout_build_enumetric.sh
RUN rm /root/checkout_build_enumetric.sh


# Default build flags for various sanitizers.
ENV SANITIZER_FLAGS_address "-fsanitize=address -fsanitize-address-use-after-scope"
ENV SANITIZER_FLAGS_hwaddress "-fsanitize=hwaddress -fuse-ld=lld -Wno-unused-command-line-argument"

# Set of '-fsanitize' flags matches '-fno-sanitize-recover' + 'unsigned-integer-overflow'.
ENV SANITIZER_FLAGS_undefined "-fsanitize=array-bounds,bool,builtin,enum,function,integer-divide-by-zero,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,unsigned-integer-overflow,unreachable,vla-bound,vptr -fno-sanitize-recover=array-bounds,bool,builtin,enum,function,integer-divide-by-zero,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,unreachable,vla-bound,vptr"

# Don't include "function" since it is unsupported on aarch64.
ENV SANITIZER_FLAGS_undefined_aarch64 "-fsanitize=array-bounds,bool,builtin,enum,integer-divide-by-zero,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,unsigned-integer-overflow,unreachable,vla-bound,vptr -fno-sanitize-recover=array-bounds,bool,builtin,enum,integer-divide-by-zero,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,unreachable,vla-bound,vptr"

ENV SANITIZER_FLAGS_memory "-fsanitize=memory -fsanitize-memory-track-origins"

ENV SANITIZER_FLAGS_thread "-fsanitize=thread"

ENV SANITIZER_FLAGS_introspector "-O0 -flto -fno-inline-functions -fuse-ld=gold -Wno-unused-command-line-argument"

# Do not use any sanitizers in the coverage build.
ENV SANITIZER_FLAGS_coverage ""

# We use unsigned-integer-overflow as an additional coverage signal and have to
# suppress error messages. See https://github.com/google/oss-fuzz/issues/910.
ENV UBSAN_OPTIONS="silence_unsigned_overflow=1"

# To suppress warnings from binaries running during compilation.
ENV DFSAN_OPTIONS='warn_unimplemented=0'

# Default build flags for coverage feedback.
ENV COVERAGE_FLAGS="-fsanitize=fuzzer-no-link"

# Use '-Wno-unused-command-line-argument' to suppress "warning: -ldl: 'linker' input unused"
# messages which are treated as errors by some projects.
ENV COVERAGE_FLAGS_coverage "-fprofile-instr-generate -fcoverage-mapping -pthread -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument"

# Default sanitizer, fuzzing engine and architecture to use.
ENV SANITIZER="address"
ENV FUZZING_ENGINE="libfuzzer"
ENV ARCHITECTURE="x86_64"

# DEPRECATED - NEW CODE SHOULD NOT USE THIS. OLD CODE SHOULD STOP. Please use
# LIB_FUZZING_ENGINE instead.
# Path to fuzzing engine library to support some old users of
# LIB_FUZZING_ENGINE.
# ENV LIB_FUZZING_ENGINE_DEPRECATED="/usr/lib/libFuzzingEngine.a"
ENV LIB_FUZZING_ENGINE_DEPRECATED=""

# Argument passed to compiler to link against fuzzing engine.
# Defaults to the path, but is "-fsanitize=fuzzer" in libFuzzer builds.
# ENV LIB_FUZZING_ENGINE="/usr/lib/libFuzzingEngine.a"
ENV LIB_FUZZING_ENGINE=""

# TODO: remove after tpm2 catchup.
ENV FUZZER_LDFLAGS ""

WORKDIR $SRC

COPY compile /usr/local/bin/

CMD ["compile"]