# Use manifest image which support all architecture
FROM debian:stretch-slim as builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu gpg wget

ENV ZENZO_VERSION 2.1.0
ENV ZENZO_URL https://github.com/ZENZO-Ecosystem/ZENZO-Core/releases/download/v2.1.0/zenzo-2.1.0-arm-linux-gnueabihf.tar.gz
ENV ZENZO_SHA256 6e6b2fc49bedb04d0230de2880c8e122e6a3ab622243a7732fe595d3dbcec07c

# install zenzo binaries
RUN set -ex \
	&& cd /tmp \
	&& wget -qO zenzo.tar.gz "$ZENZO_URL" \
	&& echo "$ZENZO_SHA256 zenzo.tar.gz" | sha256sum -c - \
	&& mkdir bin \
	&& tar -xzvf zenzo.tar.gz -C /tmp/bin --strip-components=2 "zenzo-$ZENZO_VERSION/bin/zenzo-cli" "zenzo-$ZENZO_VERSION/bin/zenzod" \
	&& cd bin \
	&& wget -qO gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-armhf" \
	&& echo "171b4a2decc920de0dd4f49278d3e14712da5fa48de57c556f99bcdabe03552e gosu" | sha256sum -c -

# Making sure the builder build an arm image despite being x64
FROM arm32v7/debian:stretch-slim

COPY --from=builder "/tmp/bin" /usr/local/bin
#EnableQEMU COPY qemu-arm-static /usr/bin

RUN chmod +x /usr/local/bin/gosu && groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin

# create data directory
ENV BITCOIN_DATA /data
RUN mkdir "$BITCOIN_DATA" \
	&& chown -R bitcoin:bitcoin "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /home/bitcoin/.zenzo \
	&& chown -h bitcoin:bitcoin /home/bitcoin/.zenzo

VOLUME /data

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 5011 5012 15011 15012
CMD ["zenzod"]