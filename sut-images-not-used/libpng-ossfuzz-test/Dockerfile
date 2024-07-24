FROM base-builder:v0.2.6tmp5-lafl0.12-lafl0.12
RUN apt-get update && \
    apt-get install -y make autoconf automake libtool zlib1g-dev

RUN git clone --depth 1 https://github.com/madler/zlib.git
RUN git clone --depth 1 https://github.com/pnggroup/libpng.git
RUN cp libpng/contrib/oss-fuzz/build.sh $SRC
WORKDIR libpng