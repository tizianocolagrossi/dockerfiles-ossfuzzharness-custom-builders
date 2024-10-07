#!/bin/bash -eux
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
apt install -y wget curl make git zip gnupg lsb-release software-properties-common python3.8-venv build-essential

wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
./llvm.sh 13
rm -f llvm.sh

# Get Rust
curl https://sh.rustup.rs -sSf | bash -s -- -y

echo 'source $HOME/.cargo/env' >> $HOME/.bashrc