################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
FROM ubuntu:18.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
apt-get -y install cron apt-transport-https ca-certificates curl software-properties-common jq && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" && \
apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get -y install docker-ce && \
rm -rf /var/lib/apt/lists/* && \
touch /var/log/cron.log

COPY lib/docker_entrypoint.sh /usr/local/bin/

RUN chmod u+x /usr/local/bin/docker_entrypoint.sh && \
    ln -s /usr/local/bin/docker_entrypoint.sh

ENTRYPOINT ["docker_entrypoint.sh"]
