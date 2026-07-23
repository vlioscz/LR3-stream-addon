ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV DEBIAN_FRONTEND=noninteractive

# Icecast2 = the streaming server radios connect to.
# Liquidsoap = the "studio" that feeds one never-dropping source per zone.
# ffmpeg    = codecs / decoding for the online fallback stream.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      icecast2 \
      liquidsoap \
      ffmpeg \
      jq \
      netcat-openbsd \
      ca-certificates \
      media-types \
 && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
COPY icecast.xml.tpl /etc/lr3/icecast.xml.tpl
COPY radio.liq.tpl /etc/lr3/radio.liq.tpl

RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
