ARG RUNNER_IMAGE
FROM ${RUNNER_IMAGE}

USER root
## General package configuration
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl

# install ansible
RUN apt-get -y install sshpass && \
    apt-get -y install python3-pip && \
    apt-get -y install sudo && \
    apt-get -y install wget curl && \
    pip3 install --upgrade pip


RUN pip3 install ansible==9.6.1
RUN pip3 install requests

RUN apt install python-is-python3 -y

RUN pip3 install docker-py

# install docker on container
RUN apt-get -y install docker.io

RUN usermod -aG docker runner
RUN usermod -aG root runner

USER runner

COPY --chown=runner:runner gpl-3.0.txt /app/gpl-3.0.txt

