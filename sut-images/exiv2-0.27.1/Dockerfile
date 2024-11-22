FROM osvaldo/base-builder:v0.2.6tmp6-aflpp-doublem

RUN git clone https://github.com/Exiv2/exiv2 $SRC/exiv2 && \
    cd $SRC/exiv2 && \
    git checkout tags/v0.27.1

COPY build.sh $SRC/