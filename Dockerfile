FROM portainer/portainer AS base

FROM alpine:latest
RUN apk add --no-cache bash
COPY --from=base / /
WORKDIR /
EXPOSE 9000
ENTRYPOINT ["/portainer"]

# RUN ["sh", "-c"]

# Add dogfish
COPY dogfish/ /usr/share/dogfish
RUN ln -s /usr/share/dogfish/dogfish /usr/bin/dogfish
COPY shell-migrations/ /usr/share/dogfish/shell-migrations
COPY dogfish/shell-migrations-shared/ /usr/share/dogfish/shell-migrations-shared

# Create log file.
RUN mkdir /data
RUN touch /data/migrations.log

# Symlink log file.
RUN mkdir /var/lib/dogfish
RUN ln -s /data/migrations.log /var/lib/dogfish/migrations.log

VOLUME /data
# Might need to touch, or otherwise setup, /data/migrations.log.