FROM osvaldo/base-builder:latest

RUN apt-get install --no-install-recommends -y make wget cmake qtbase5-dev libcups2-dev autoconf automake autotools-dev libtool
RUN wget -O ncurses-6.1.tar.gz https://github.com/unifuzz/unibench/raw/834f2975d9fe605691159b22304b8897569e0549/ncurses-6.1.tar.gz && \
    tar -xvzf ncurses-6.1.tar.gz && rm ncurses-6.1.tar.gz
COPY build.sh $SRC/
