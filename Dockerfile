FROM ubuntu:24.04

ARG BYOND_MAJOR=516
ARG BYOND_MINOR=1687

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libc6:i386 \
        libmariadb3:i386 \
        libstdc++6:i386 \
        make \
        unzip \
        wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN wget -q "https://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" \
    && unzip -q "${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" \
    && rm "${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" \
    && cd /opt/byond \
    && make here >/dev/null

WORKDIR /opt/immortal-imperium
COPY . .

RUN ln -s /usr/lib/i386-linux-gnu/libmariadb.so.3 libmariadb.so \
    && /bin/bash -c 'source /opt/byond/bin/byondsetup && DreamMaker IS12Warfare.dme'

ENTRYPOINT ["/bin/bash", "-c", "source /opt/byond/bin/byondsetup && exec DreamDaemon IS12Warfare.dmb 8000 -invisible -trusted"]
