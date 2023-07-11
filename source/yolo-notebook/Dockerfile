ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER 0
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
                   https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm \
                   http://mirror.stream.centos.org/9-stream/CRB/x86_64/os/Packages/ladspa-1.13-28.el9.x86_64.rpm \
                   https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-9.noarch.rpm \
 && dnf -y install libGL \
 && dnf clean all

RUN pip install --no-cache-dir ultralytics==8.0.124

ENV AWS_S3_ENDPOINT=${MINIO_ENDPOINT}
ENV AWS_S3_BUCKET=${MINIO_BUCKET}
ENV AWS_SECRET_ACCESS_KEY=${MINIO_ACCESS_KEY}
ENV AWS_ACCESS_KEY=${MINIO_SECRETKEY}
