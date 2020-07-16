FROM ubuntu:bionic

ENV BUILD_DEPS curl autoconf automake ragel bison flex g++ libboost-all-dev libtool make pkg-config default-libmysqlclient-dev libssl-dev virtualenv libluajit-5.1-dev libsodium-dev default-libmysqlclient-dev postgresql-server-dev-10 libmaxminddb-dev libmaxminddb0 libgeoip1 libgeoip-dev libyaml-cpp-dev libsqlite3-dev
ENV RUNTIME_DEPS python3 python3-pip mysql-client libmysqlclient20 postgresql libyaml-cpp-dev libgeoip1 libluajit-5.1-2

ENV PowerDNS_VERSION 4.0.9
ENV PowerDNS_VERSION_SHA1 4ef591fa9f3cec2b9ec051fd2d8793a331c71304
ENV PowerDNS_VERSION_URL https://github.com/PowerDNS/pdns/archive/auth-${PowerDNS_VERSION}.tar.gz

ENV DEBIAN_FRONTEND noninteractive

RUN set -e && \
    cd /tmp && \
    # Install dependencies
    apt update && \
    apt install -y $BUILD_DEPS && \
    # Download
    curl -o pdns.tar.gz -fSL ${PowerDNS_VERSION_URL} && \
    echo "${PowerDNS_VERSION_SHA1} pdns.tar.gz" | sha1sum -c - && \
    tar xzvf pdns.tar.gz && \
    cd pdns-auth-${PowerDNS_VERSION} && \
    # Build
    autoreconf -vi && \
    ./configure --with-modules="bind gmysql gpgsql gsqlite3 geoip remote" --enable-tools --with-lua --with-luajit --with-libsodium && \
    make && \
    make install && \
    # Clean up
    apt purge -y $BUILD_DEPS && \
    apt autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/*

RUN apt update && \
    apt install -y $RUNTIME_DEPS && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 install --no-cache-dir envtpl

RUN groupadd -g 107 -r pdns && \
    useradd -u 103 -g 107 -r -d /var/spool/pdns -s /bin/false -c PowerDNS pdns && \
    mkdir -p /etc/pdns /var/spool/pdns

ENV PDNS_guardian=yes \
    PDNS_setuid=pdns \
    PDNS_setgid=pdns \
    PDNS_launch=gmysql

EXPOSE 53 53/udp 8081

COPY pdns.conf.tpl /
COPY docker-entrypoint.sh /

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "/usr/local/sbin/pdns_server" ]
