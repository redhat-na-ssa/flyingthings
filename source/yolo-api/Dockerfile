# hadolint global ignore=DL3041
FROM quay.io/centos/centos:stream9

ENV STI_SCRIPTS_PATH=/usr/libexec/s2i/
COPY s2i/bin/ $STI_SCRIPTS_PATH
COPY usr/ /usr/

### Setup user for build execution and application runtime
ENV APP_ROOT=/opt/app-root

RUN mkdir -p \
      ${APP_ROOT}/bin \
      ${APP_ROOT}/src && \
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
    curl -s -L "${MINIO_CLIENT_URL}/mc" -o ${APP_ROOT}/bin/mc && \
    chmod +x ${APP_ROOT}/bin/mc

# set no-cache-dir for pip
ENV PIP_NO_CACHE_DIR=1

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py app.sh ./

VOLUME /models

USER 1001

CMD ["/opt/app-root/src/app.sh"]
