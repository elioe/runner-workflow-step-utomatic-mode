ARG IMAGE
FROM ${IMAGE}

USER root

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl vim unzip

# install ansible
RUN apt-get -y install sshpass && \
    apt-get -y install python3-pip && \
    apt-get -y install sudo && \
    apt-get -y install jq && \
    pip3 install --upgrade pip

# install ansible
RUN pip3 install --upgrade pip && \
    pip3 install ansible==9.6.1

RUN ln -s /usr/bin/python3 /usr/bin/python

RUN pip3 install docker-py

# install docker on container
RUN apt-get -y install docker.io


RUN ansible-galaxy collection install community.docker  --force

RUN usermod -aG docker runner
RUN usermod -aG root runner

USER runner
COPY --chown=runner:runner plugins/ /app/runner/plugins/
