FROM portainer/portainer AS base

FROM alpine:latest
COPY --from=base / /
WORKDIR /
EXPOSE 9000
ENTRYPOINT ["/portainer"]

# RUN ["sh", "-c"]
RUN apk add --no-cache bash
RUN mkdir /data
RUN touch /data/migrations.log
#COPY migrations.log /data/migrations.log
COPY dogfish/ /usr/share/dogfish
COPY shell-migrations/ /usr/share/dogfish/shell-migrations

RUN ln -s /usr/share/dogfish/dogfish /usr/bin/dogfish
RUN mkdir /var/lib/dogfish
RUN ln -s /data/migrations.log /var/lib/dogfish/migrations.log
VOLUME /data
# Might need to touch, or otherwise setup, /data/migrations.log.