# BASE
ARG NODE=node
ARG NODE_VERSION=20
FROM ${NODE}:${NODE_VERSION}-alpine AS base-alpine
EXPOSE 1337

FROM base-alpine

RUN mkdir -p /srv/app && chown 1000:1000 -R /srv/app

ARG STRAPI_VERSION=4.24.2

ENV STRAPI_VERSION=$STRAPI_VERSION

ARG GITHUB_ACTIONS=0

ENV GITHUB_ACTIONS=$GITHUB_ACTIONS

# Strapi >=5.51 pulls in deps requiring node >=22.13 while v4 projects pin node <=20.x.
# Yarn v1 treats engine mismatches as fatal (npm only warns), which breaks v4 -> v5 upgrades.
ENV YARN_IGNORE_ENGINES=true

WORKDIR /srv/app

VOLUME /srv/app

COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod 777 /usr/local/bin/docker-entrypoint.sh && ln -s /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["strapi"]
