# Use manifest image which support all architecture
FROM debian:stretch-slim as builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu gpg wget

ENV ZENZO_VERSION 2.1.0
ENV ZENZO_URL https://github.com/ZENZO-Ecosystem/ZENZO-Core/releases/download/v2.1.0/zenzo-2.1.0-aarch64-linux-gnu.tar.gz
ENV ZENZO_SHA256 f613022307e1af7e95cf91e6940c1ad62f74b1beafcee9645b89ac43e3c4f963

# install zenzo binaries
RUN set -ex \
	&& cd /tmp \
	&& wget -qO zenzo.tar.gz "$ZENZO_URL" \
	&& echo "$ZENZO_SHA256 zenzo.tar.gz" | sha256sum -c - \
	&& mkdir bin \
	&& tar -xzvf zenzo.tar.gz -C /tmp/bin --strip-components=2 "zenzo-$ZENZO_VERSION/bin/zenzo-cli" "zenzo-$ZENZO_VERSION/bin/zenzod" \
	&& cd bin \
	&& wget -qO gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-arm64" \
	&& echo "5e279972a1c7adee65e3b5661788e8706594b458b7ce318fecbd392492cc4dbd gosu" | sha256sum -c -

# Making sure the builder build an arm image despite being x64
FROM arm64v8/debian:stretch-slim

COPY --from=builder "/tmp/bin" /usr/local/bin
#EnableQEMU COPY qemu-aarch64-static /usr/bin

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
