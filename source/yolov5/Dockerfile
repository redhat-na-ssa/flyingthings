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

ARG MINIO_CLIENT_URL=https://dl.min.io/client/mc/release/linux-amd64

RUN dnf -y --setopt=tsflags=nodocs upgrade && \
    dnf install -y git wget libGL python3-pip && \
    dnf clean all && \
    curl -s -L "${MINIO_CLIENT_URL}/mc" -o /usr/local/bin/mc && \
    chmod +x /usr/local/bin/mc

# set no-cache-dir when building images
ENV PIP_NO_CACHE_DIR=1

# ARG YOLOv5_VERSION=v7.0
# ARG SITE_PATH=/usr/local/lib/python3.9/site-packages

# RUN mkdir -p "${SITE_PATH}" && \
#     cd "${SITE_PATH}" && \
#     git clone --branch ${YOLOv5_VERSION} \
#       --depth 1 https://github.com/ultralytics/yolov5.git && \
#     pip install --no-cache-dir -U pip setuptools && \
#     pip install --no-cache-dir \
#       -r "${SITE_PATH}/yolov5/requirements.txt" && \
#     rm -rf "${SITE_PATH}/yolov5/.git"

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

# VOLUME "${SITE_PATH}/yolov5/training"

USER 1001
