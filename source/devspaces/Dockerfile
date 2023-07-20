FROM quay.io/centos/centos:stream9

WORKDIR /opt/app-root/src

RUN dnf install -y git wget libGL python39 python3-pip && \
    pip-3.9 install --upgrade pip && \
    dnf -y  --setopt=tsflags=nodocs update && \
    dnf -y install libGL && \
    dnf -y clean all --enablerepo='*' && \
    curl -o tekton.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/pipeline/latest/tkn-linux-amd64.tar.gz && \
    tar xzf tekton.tar.gz --no-same-owner && \
    mv tkn /usr/local/bin && \
    rm tekton.tar.gz

RUN pip install --no-cache-dir ultralytics==8.0.124 opencv-python jinja2

USER 1001

WORKDIR /opt/app-root/src
