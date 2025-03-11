#!/bin/bash -eu
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

# Run the OSS-Fuzz script in the curl-fuzzer project.

export AFL_LLVM_CMPLOG=1
./ossfuzz.sh
# find /out/ -type f ! -name "curl_fuzzer" -delete
find /out/ -type f -name "curl*" ! -name "curl_fuzzer" -delete
mv /out/curl_fuzzer /out/curl_fuzzer.cmplog
touch $OUT/afl_cmplog.txt
unset AFL_LLVM_CMPLOG

./ossfuzz.sh
cp $(ldd $OUT/curl_fuzzer | cut -d" " -f3) $OUT

