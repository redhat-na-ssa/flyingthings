FROM ubi9:latest
# FROM quay.io/centos/centos:stream9

USER 0

WORKDIR /opt/app-root/src

ENV GIT_URL=myrepo
ENV GIT_BRANCH=mybranch
ENV MINIO_BUCKET=flyingthings
ENV MINIO_ACCESSKEY=minioadmin
ENV MINIO_SECRETKEY=minioadmin
ENV MINIO_CLIENT_URL=https://dl.min.io/client/mc/release/linux-amd64
ENV WORKSPACE_DIR=/opt/app-root/src/workspace
ENV MINCFG=$WORKSPACE_DIR/miniocfg

RUN mkdir -p ${WORKSPACE_DIR}

WORKDIR ${WORKSPACE_DIR}

COPY bucket-ops.sh ${WORKSPACE_DIR}/

RUN chown -R 1001:1001 ${WORKSPACE_DIR}

USER 1001

WORKDIR ${WORKSPACE_DIR}
