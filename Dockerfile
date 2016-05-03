FROM studionone/nginx-php7:latest

MAINTAINER Greg Beaven <greg@studionone.com.au>

RUN apt-get update && apt-get install -y git \
    python \
    gcc \
    make \
    g++ \
    wget \
    php7.0-dev

# install dependencies
RUN apt-get update
RUN apt-get -y install git subversion make g++ python curl chrpath && apt-get clean

# depot tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /usr/local/depot_tools
ENV PATH $PATH:/usr/local/depot_tools

# install v8
RUN cd /usr/local/src && fetch v8 && \
    cd /usr/local/src/v8 && git checkout 4.9.111 && gclient sync && make x64.release library=shared snapshot=off -j4 && \
    mkdir -p /usr/local/lib && \
    cp /usr/local/src/v8/out/x64.release/lib.target/lib*.so /usr/local/lib && \
    echo "create /usr/local/lib/libv8_libplatform.a\naddlib /usr/local/src/v8/out/x64.release/obj.target/tools/gyp/libv8_libplatform.a\nsave\nend" | ar -M && \
    cp -R /usr/local/src/v8/include /usr/local && \
    chrpath -r '$ORIGIN' /usr/local/lib/libv8.so && \
    rm -fR /usr/local/src/v8

# get v8js, compile and install
ENV NO_INTERACTION 1
RUN git clone https://github.com/preillyme/v8js.git /usr/local/src/v8js && \
    cd /usr/local/src/v8js && phpize && ./configure --with-v8js=/usr/local && \
    make all test install && \
    echo extension=v8js.so > /etc/php/7.0/cli/conf.d/99-v8js.ini && \
    echo extension=v8js.so > /etc/php/7.0/fpm/conf.d/99-v8js.ini && \
    chmod 0777 /etc/php/7.0/fpm/conf.d/99-v8js.ini && \
    chmod 0777 /etc/php/7.0/cli/conf.d/99-v8js.ini && \
    rm -fR /usr/local/src/v8js && \
    service nginx reload
