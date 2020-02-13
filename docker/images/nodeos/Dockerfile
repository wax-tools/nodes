ARG WAX_IMAGE=waxteam/production
ARG WAX_IMAGE_VERSION=latest

FROM $WAX_IMAGE:$WAX_IMAGE_VERSION

# No user is defined here. It is expected that the container be run with an appropriate user

COPY lib/docker-entrypoint.sh /usr/local/bin/
RUN ln -s /usr/local/bin/docker-entrypoint.sh / # backwards compatability

ENTRYPOINT ["docker-entrypoint.sh"]
