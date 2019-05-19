FROM portainer/portainer:1.19.2 AS base

FROM neilpang/acme.sh:latest
# TODO: Pick either CURL or HTTPie and use that consistently. 
RUN apk add --no-cache bash python py-pip ca-certificates curl mosquitto-clients
RUN pip install --upgrade pip
RUN pip install httpie httpie-unixsocket && rm -rf /var/cache/apk/*
COPY --from=base / /
WORKDIR /data/
EXPOSE 9000

# RUN ["sh", "-c"]

# Put docker in $PATH
RUN ln -s /docker /usr/bin/docker

# Set up the entrypoint
COPY go-init /bin/go-init
COPY entrypoint.sh /usr/bin/entrypoint.sh
COPY exitpoint.sh /usr/bin/exitpoint.sh
ENTRYPOINT ["go-init"]
CMD ["-pre", "entrypoint.sh", "-main", "/portainer -H unix:///var/run/docker.sock --ssl --sslcert /run/secrets/cert --sslkey /run/secrets/key", "-post", "exitpoint.sh"]


# Add dogfish
COPY dogfish/ /usr/share/dogfish
RUN ln -s /usr/share/dogfish/dogfish /usr/bin/dogfish
COPY shell-migrations/ /usr/share/dogfish/shell-migrations
COPY dogfish/shell-migrations-shared/ /usr/share/dogfish/shell-migrations-shared

# Create log file and gen-secrets indicator file.
RUN touch /data/migrations.log /data/gen-secrets 

# Symlink log file.
RUN mkdir /var/lib/dogfish
RUN ln -s /data/migrations.log /var/lib/dogfish/migrations.log

# Add the mqtt listeners. 
COPY mqtt-scripts/ /usr/share/mqtt-scripts
RUN chmod +x /usr/share/mqtt-scripts/*
WORKDIR /usr/share/mqtt-scripts
VOLUME /data
# Might need to touch, or otherwise setup, /data/migrations.log.