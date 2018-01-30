FROM studionone/nginx-php7:latest

MAINTAINER Greg Beaven <greg@studionone.com.au>

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    python \
    wget \
    curl \
    chrpath \
    libglib2.0-dev \
    php7.1-dev

# depot tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /usr/local/depot_tools
ENV PATH $PATH:/usr/local/depot_tools
ENV NO_INTERACTION 1

# install v8
WORKDIR /usr/local/src
RUN fetch v8
WORKDIR v8 
RUN git checkout 6.4.388.18
RUN ls tools/dev
#RUN gclient help

RUN tools/dev/v8gen.py -vv x64.release -- is_component_build=true

# Build
RUN ninja -C out.gn/x64.release/
#RUN mkdir -p /usr/local/{lib,include}

RUN mkdir -p /opt/v8/lib
RUN mkdir -p /opt/v8/include

RUN cp out.gn/x64.release/lib*.so out.gn/x64.release/*_blob.bin \
    out.gn/x64.release/icudtl.dat /opt/v8/lib/
    
RUN cp -R include/* /opt/v8/include/

# get v8js, compile and install

RUN git clone https://github.com/phpv8/v8js.git /usr/local/src/v8js
WORKDIR /usr/local/src/v8js
RUN git fetch --tags && \
    git checkout tags/2.1.0 && \
    phpize && \
    ./configure --with-v8js=/opt/v8 && \
    make all test install && \
    echo extension=v8js.so > /etc/php/7.1/cli/conf.d/99-v8js.ini && \
    echo extension=v8js.so > /etc/php/7.1/fpm/conf.d/99-v8js.ini && \
    chmod 0777 /etc/php/7.1/fpm/conf.d/99-v8js.ini && \
    chmod 0777 /etc/php/7.1/cli/conf.d/99-v8js.ini && \
    rm -fR /usr/local/src/v8js

RUN service nginx reload
