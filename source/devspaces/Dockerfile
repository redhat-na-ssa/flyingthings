# FROM quay.io/centos/centos:stream9
FROM registry.redhat.io/devspaces/udi-rhel8

WORKDIR /opt/app-root/src

RUN dnf install -y git wget libGL && \
    dnf -y clean all --enablerepo='*' && \
    curl -o tekton.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/pipeline/latest/tkn-linux-amd64.tar.gz && \
    tar xzf tekton.tar.gz --no-same-owner && \
    mv tkn /usr/local/bin && \
    rm tekton.tar.gz

RUN pip install --no-cache-dir ultralytics==8.0.124 opencv-python jinja2

USER 1001

WORKDIR /opt/app-root/src
