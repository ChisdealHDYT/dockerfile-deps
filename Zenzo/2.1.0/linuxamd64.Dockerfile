FROM debian:stretch-slim as builder

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu gpg wget

ENV ZENZO_VERSION 2.1.0
ENV ZENZO_URL https://github.com/ZENZO-Ecosystem/ZENZO-Core/releases/download/v2.1.0/zenzo-2.1.0-x86_64-linux-gnu.tar.gz
ENV ZENZO_SHA256 1f3a85d2344bd92255b438a15ed4fd04398b5a78e0ee42133798ff49a554e72d

ENV ZENZO_URL_SH https://raw.githubusercontent.com/ChisdealHDYT/dockerfile-deps/master/Zenzo/2.1.0/docker-entrypoint.sh

# install zenzo binaries
RUN set -ex \
	&& cd /tmp \
	&& wget -qO zenzo.tar.gz "$ZENZO_URL" \
	&& wget -qO docker-entrypoint.sh "$ZENZO_URL_SH" \
	&& echo "$ZENZO_SHA256 zenzo.tar.gz" | sha256sum -c - \
	&& mkdir bin \
	&& tar -xzvf zenzo.tar.gz -C /tmp/bin --strip-components=2 "zenzo-$ZENZO_VERSION/bin/zenzo-cli" "zenzo-$ZENZO_VERSION/bin/zenzod" \
	&& cd bin \
	&& wget -qO gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-amd64" \
	&& echo "0b843df6d86e270c5b0f5cbd3c326a04e18f4b7f9b8457fa497b0454c4b138d7 gosu" | sha256sum -c -

FROM debian:stretch-slim
COPY --from=builder "/tmp/bin" /usr/local/bin

RUN chmod +x /usr/local/bin/gosu && groupadd -r zenzo && useradd -r -m -g zenzo zenzo

# create data directory
ENV BITCOIN_DATA /data
RUN mkdir "$BITCOIN_DATA" \
	&& chown -R zenzo:zenzo "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /home/zenzo/.zenzo \
	&& chown -h zenzo:zenzo /home/zenzo/.zenzo

VOLUME /data

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 5011 5012 15011 15012
CMD ["zenzod"]
