FROM registry.access.redhat.com/ubi9/python-39

# set no-cache-dir when building images
ENV PIP_NO_CACHE_DIR=1

USER 0

# update base image
# (ubi images are not released that often)
RUN dnf -y  --setopt=tsflags=nodocs update && \
    dnf -y install libGL jq && \
    dnf -y clean all --enablerepo='*'

# install: oc
ARG OC4_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz"

RUN curl -sL "${OC4_URL}" -o oc.tgz && \
    sha256sum < oc.tgz && \
    tar -C /opt/app-root/bin -zxf oc.tgz oc && \
    /opt/app-root/bin/oc completion bash > /etc/bash_completion.d/oc && \
    rm oc.tgz && \
    fix-permissions /opt/app-root/lib

USER 1001

# need jinja2
RUN pip install -U Jinja2==3.1.* opencv-python==4.6.0.*

# Install micropipenv to deploy packages from Pipfile.lock
# RUN pip install -U "micropipenv[toml]"

# Copy files
# COPY Pipfile.lock ./

