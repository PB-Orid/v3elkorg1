# needs full openssl support
FROM anapsix/alpine-java:latest

# updates to latest version
ENV VERSION=6.2.1
ENV PKGS="s6 ca-certificates openssl wget unzip git tar nodejs coreutils"
ENV ES_URL="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${VERSION}.tar.gz"
ENV LS_URL="https://artifacts.elastic.co/downloads/logstash/logstash-${VERSION}.tar.gz"
ENV  K_URL="https://artifacts.elastic.co/downloads/kibana/kibana-${VERSION}-linux-x86_64.tar.gz"
ENV GEOCITY_URL="http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz"

# meta
LABEL \
	org.label-schema.maintainer="me codar nl" \
	org.label-schema.name="elk6" \
	org.label-schema.description="Docker version of Elasticsearch, Logstash and Kibana 6 based on Alpine Linux" \
	org.label-schema.version="${VERSION}" \
	org.label-schema.vcs-url="https://github.com/PB-Orid/v3elkorg1" \
	org.label-schema.schema-version="1.0"

#  /tmp all in
WORKDIR	/tmp

#  a nice small images of elk
RUN apk    add --update --no-cache ${PKGS} \
	&& mkdir -p /opt/elasticsearch /opt/kibana /opt/logstash/patterns /opt/logstash/databases /var/lib/elasticsearch \
	&& adduser -D -h /opt/elasticsearch elasticsearch \
	&& adduser -D -h /opt/logstash logstash \
	&& adduser -D -h /opt/kibana kibana \
	&& wget -q $ES_URL -O elasticsearch.tar.gz \
	&& wget -q $LS_URL -O logstash.tar.gz \
	&& wget -q  $K_URL -O kibana.tar.gz \
	&& wget -q $GEOCITY_URL -O geocity.gz \
	&& tar -zxf elasticsearch.tar.gz --strip-components=1 -C /opt/elasticsearch \
	&& tar -zxf logstash.tar.gz --strip-components=1 -C /opt/logstash \
	&& tar -zxf kibana.tar.gz --strip-components=1 -C /opt/kibana \
	&& gunzip -c geocity.gz > /opt/logstash/databases/GeoLiteCity.dat \
	&& git clone https://github.com/logstash-plugins/logstash-patterns-core.git \
	&& cp -a logstash-patterns-core/patterns/* /opt/logstash/patterns/ \
	&& /opt/logstash/bin/logstash-plugin install logstash-input-beats \
	&& ln -s /opt/jdk/bin/java /usr/bin/java \
	&& rm -rf /tmp/*

# this will create layout for the filesystem
COPY files/root/ /

# fix, resets permissions at start
RUN	   chmod a+x /service/*/run

# elk ports
# 5601 kibana
# 9200 elasticsearch rest
# 9300 elasticsearch nodes
# 5044 filebeat plugin
EXPOSE 5601/tcp 9200/tcp 9300/tcp 5044/tcp

# volumes
VOLUME /var/lib/elasticsearch

# manage with s6
ENTRYPOINT ["/bin/s6-svscan","/service"]
