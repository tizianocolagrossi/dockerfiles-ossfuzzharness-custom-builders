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

# Using multi-stage build to copy some LLVM binaries needed in the runner image.
FROM osvaldo/oss-base-clang-10 AS base-clang-10
FROM osvaldo/oss-base-clang AS base-clang


FROM osvaldo/oss-base-image
RUN apt-get update && apt-get install -y git ssh parallel libarchive-tools pv

# Copy the binaries needed for code coverage and crash symbolization.
COPY --from=base-clang /usr/bin/llvm-cov-13 \
     /usr/bin/llvm-profdata-13 \
     /usr/bin/llvm-symbolizer-13 \
     /usr/local/bin/

COPY --from=base-clang /src/desockmulti/desockmulti.so /usr/lib/desockmulti.so

COPY --from=base-clang-10 /usr/bin/llvm-cov-10 \
     /usr/bin/llvm-profdata-10 \
     /usr/bin/llvm-symbolizer-10 \
     /usr/local/bin/

#RUN sudo sysctl -w kernel.core_pattern="core"
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh \
  git clone git@github.com:tizianocolagrossi/BAAFLTriage.git /src/BAAFLTriage 


COPY install_deps.sh /
RUN /install_deps.sh && rm /install_deps.sh


ENV FUZZ_OUT=/fuzz_out
RUN mkdir -p $FUZZ_OUT

ENV DEDUP_BUILD=/dedup_build
RUN mkdir -p $DEDUP_BUILD

# Do this last to make developing these files easier/faster due to caching.
COPY analyze \
    /usr/local/bin/

CMD [ "analyze" ]