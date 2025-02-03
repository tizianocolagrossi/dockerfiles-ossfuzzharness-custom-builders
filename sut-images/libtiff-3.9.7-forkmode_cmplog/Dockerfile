FROM osvaldo/base-builder:latest

RUN apt-get install --no-install-recommends -y make wget cmake qtbase5-dev libcups2-dev autoconf automake autotools-dev libtool
RUN wget -O libtiff-3.9.7.zip https://github.com/unifuzz/unibench/raw/834f2975d9fe605691159b22304b8897569e0549/libtiff-3.9.7.zip && \
    unzip libtiff-3.9.7.zip && rm libtiff-3.9.7.zip
COPY build.sh $SRC/