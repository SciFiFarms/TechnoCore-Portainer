FROM portainer/portainer AS base

FROM alpine:latest
# TODO: Pick either CURL or HTTPie and use that consistently. 
RUN apk add --no-cache bash python py-pip ca-certificates curl mosquitto-clients
RUN pip install --upgrade pip
RUN pip install httpie httpie-unixsocket && rm -rf /var/cache/apk/*
COPY --from=base / /
WORKDIR /data/
EXPOSE 9000
CMD dogfish migrate & /portainer -H unix:///var/run/docker.sock

# RUN ["sh", "-c"]

# Add dogfish
COPY dogfish/ /usr/share/dogfish
RUN ln -s /usr/share/dogfish/dogfish /usr/bin/dogfish
COPY shell-migrations/ /usr/share/dogfish/shell-migrations
COPY dogfish/shell-migrations-shared/ /usr/share/dogfish/shell-migrations-shared

# Create log file.
RUN touch /data/migrations.log

# Symlink log file.
RUN mkdir /var/lib/dogfish
RUN ln -s /data/migrations.log /var/lib/dogfish/migrations.log

COPY mqtt-scripts/ /usr/share/mqtt-scripts
WORKDIR /usr/share/mqtt-scripts
VOLUME /data
# Might need to touch, or otherwise setup, /data/migrations.log.