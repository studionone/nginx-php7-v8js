FROM studionone/nginx-php7:latest

MAINTAINER Greg Beaven <greg@studionone.com.au>

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    python \
    wget \
    chrpath \
    libglib2.0-dev \
    php7.1-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH $PATH:/usr/local/depot_tools
ENV NO_INTERACTION 1

# depot tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /usr/local/depot_tools && \
    # install v8
    cd /usr/local/src && \
    fetch v8 && \
    cd v8 && \
    git checkout 6.5-lkgr && \
    ls tools/dev && \
    gclient sync && \
    tools/dev/v8gen.py -vv x64.release -- is_component_build=true && \
    # Build
    ninja -C out.gn/x64.release/ && \
    mkdir -p /opt/v8/lib && \
    mkdir -p /opt/v8/include && \
    cp out.gn/x64.release/lib*.so out.gn/x64.release/*_blob.bin \
    out.gn/x64.release/icudtl.dat /opt/v8/lib/ && \
    cp -R include/* /opt/v8/include/ && \
    rm -rf /usr/local/depot_tools /usr/local/src/v8

# get v8js, compile and install
RUN git clone -b 2.1.0 --single-branch https://github.com/phpv8/v8js.git /usr/local/src/v8js && \
    cd /usr/local/src/v8js && \
    phpize && \
    ./configure --with-v8js=/opt/v8 && \
    make all test install && \
    echo extension=v8js.so > /etc/php/7.1/cli/conf.d/99-v8js.ini && \
    echo extension=v8js.so > /etc/php/7.1/fpm/conf.d/99-v8js.ini && \
    chmod 0777 /etc/php/7.1/fpm/conf.d/99-v8js.ini && \
    chmod 0777 /etc/php/7.1/cli/conf.d/99-v8js.ini && \
    rm -rf /usr/local/src/v8js

RUN service nginx reload
