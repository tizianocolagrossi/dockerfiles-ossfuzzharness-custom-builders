#!/bin/bash -eu
# Copyright 2018 Google Inc.
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

./fuzzing/oss-fuzz-build.sh
cp $WORK/bin/gm "${OUT}/"

export AFL_LLVM_CMPLOG=1

./fuzzing/oss-fuzz-build.sh
cp $WORK/bin/gm "${OUT}/gm.cmplog"

touch $OUT/afl_cmplog.txt
unset AFL_LLVM_CMPLOG

ldd "$WORK/bin/gm.cmplog" | while read -r line; do
    # Only process lines with a valid path (those that are not "not found")
    # echo $line
    if [[ "$line" == *" => "* ]]; then
        echo "Copy $line"
        second_part=$(echo "$line" | cut -d'>' -f2-)
        file_path="${second_part%% (*}"
        echo "cp $file_path in out"
        cp $file_path $OUT/
    fi
done

ldd "$WORK/bin/gm" | while read -r line; do
    # Only process lines with a valid path (those that are not "not found")
    # echo $line
    if [[ "$line" == *" => "* ]]; then
        echo "Copy $line"
        second_part=$(echo "$line" | cut -d'>' -f2-)
        file_path="${second_part%% (*}"
        echo "cp $file_path in out"
        cp $file_path $OUT/
    fi
done