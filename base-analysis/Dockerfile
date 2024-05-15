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
FROM oss-base-image

COPY install_deps.sh /
RUN /install_deps.sh && rm /install_deps.sh


ENV FUZZ_OUT=/fuzz_out
RUN mkdir -p $FUZZ_OUT

# Do this last to make developing these files easier/faster due to caching.
COPY analyze \
    /usr/local/bin/

CMD [ "analyze" ]