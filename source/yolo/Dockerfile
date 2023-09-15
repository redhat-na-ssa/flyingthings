FROM quay.io/centos/centos:stream9

ENV STI_SCRIPTS_PATH=/usr/libexec/s2i/
COPY s2i/bin/ $STI_SCRIPTS_PATH
COPY usr/ /usr/

### Setup user for build execution and application runtime
ENV APP_ROOT=/opt/app-root

RUN mkdir -p ${APP_ROOT}/{bin,src} && \
    chmod -R u+x ${APP_ROOT}/bin && \
    chgrp -R 0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT}

ENV PATH=${APP_ROOT}/bin:${PATH} \
    HOME=${APP_ROOT}/src

WORKDIR ${APP_ROOT}/src

RUN dnf -y --setopt=tsflags=nodocs upgrade && \
    dnf install -y git wget libGL python3-pip && \
    dnf clean all

# set no-cache-dir when building images
ENV PIP_NO_CACHE_DIR=1

ARG YOLOv5_VERSION=v7.0

RUN mkdir -p /usr/local/lib/python3.9/site-packages && \
 cd /usr/local/lib/python3.9/site-packages && \
 git clone --branch ${YOLOv5_VERSION} --depth 1 https://github.com/ultralytics/yolov5.git && \
 pip install --no-cache-dir -U pip setuptools && \
 pip install --no-cache-dir \
    -r /usr/local/lib/python3.9/site-packages/yolov5/requirements.txt && \
 rm -rf /usr/local/lib/python3.9/site-packages/yolov5/.git

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

USER 1001
