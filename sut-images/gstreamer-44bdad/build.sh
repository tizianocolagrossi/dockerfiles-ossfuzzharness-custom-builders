#!/bin/bash -eu
# Copyright 2017 Google Inc.
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

# pushd $SRC/gstreamer
# git fetch --all -pP
# git checkout 44bdad
# git submodule update --init --recursive
# popd

# pushd $SRC/gst-plugins-base
# git fetch --all -pP
# git checkout 01d1bbd1dadf2992769d351023d624eacb0a92c5
# git submodule update --init --recursive
# popd

# pushd $SRC/gst-ci
# git checkout 8f8cd9ec4b940a01bfbc38be260f9cccfed9b7a4
# git submodule update --init --recursive
# popd

#!/bin/bash -eu
# Copyright 2017 Google Inc.
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

$SRC/gst-ci/fuzzing/build-oss-fuzz.sh

