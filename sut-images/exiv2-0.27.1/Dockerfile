FROM osvaldo/base-builder:latest

RUN git clone https://github.com/Exiv2/exiv2 $SRC/exiv2 && \
    cd $SRC/exiv2 && \
    git checkout tags/v0.27.1

COPY build.sh $SRC/