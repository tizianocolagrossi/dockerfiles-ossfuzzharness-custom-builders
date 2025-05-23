# Copyright 2016 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

# Build rust stuff in its own image. We only need the resulting binaries.
# Keeping the rust toolchain in the image wastes 1 GB.
FROM osvaldo/oss-base-image AS temp-runner-binary-builder

RUN apt-get update && apt-get install -y cargo
RUN cargo install rustfilt

# Using multi-stage build to copy some LLVM binaries needed in the runner image.
FROM osvaldo/oss-base-clang AS base-clang

# Real image that will be used later.
FROM osvaldo/oss-base-image

#RUN sudo sysctl -w kernel.core_pattern="core"

COPY --from=temp-runner-binary-builder /root/.cargo/bin/rustfilt /usr/local/bin

# Copy the binaries needed for code coverage and crash symbolization.
COPY --from=base-clang /usr/bin/llvm-cov-13 \
     /usr/bin/llvm-profdata-13 \
     /usr/bin/llvm-symbolizer-13 \
     /usr/local/bin/ 

COPY --from=base-clang /lib/x86_64-linux-gnu/libLLVM-13.so.1 \
     /lib/x86_64-linux-gnu/libedit.so.2 \
     /lib/x86_64-linux-gnu/libbsd.so.0 \
     /lib/x86_64-linux-gnu/

COPY install_deps.sh /
RUN /install_deps.sh && rm /install_deps.sh

ENV ASAN_OPTIONS="abort_on_error=1:disable_coredump=0:unmap_shadow_on_exit=1:alloc_dealloc_mismatch=0:allocator_may_return_null=1:allocator_release_to_os_interval_ms=500:check_malloc_usable_size=0:detect_container_overflow=1:detect_odr_violation=0:detect_leaks=1:detect_stack_use_after_return=1:fast_unwind_on_fatal=0:handle_abort=1:handle_segv=1:handle_sigill=1:max_uar_stack_size_log=16:print_scariness=1:quarantine_size_mb=10:strict_memcmp=1:strip_path_prefix=/workspace/:symbolize=1:use_sigaltstack=1:dedup_token_length=3"
# ENV MSAN_OPTIONS="abort_on_error=1:disable_coredump=0:print_stats=1:strip_path_prefix=/workspace/:symbolize=1:dedup_token_length=3"
ENV UBSAN_OPTIONS="abort_on_error=1:disable_coredump=0:print_stacktrace=1:print_summary=1:silence_unsigned_overflow=1:strip_path_prefix=/workspace/:symbolize=1:dedup_token_length=3"

ENV ASAN_SYMBOLIZER_PATH=/usr/local/bin/llvm-symbolizer-13

ENV IN=/in
RUN mkdir -p $IN

ENV OUT=/out
RUN mkdir -p $OUT

COPY .bashrc /root/
COPY load-libs.sh load-src.sh /work/
WORKDIR /work

