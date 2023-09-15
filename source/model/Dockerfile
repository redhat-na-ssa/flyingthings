# FROM quay.io/centos/centos:stream9
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER 0
WORKDIR /opt/app-root/src

# RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
#                    https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm \
#                    http://mirror.stream.centos.org/9-stream/CRB/x86_64/os/Packages/ladspa-1.13-28.el9.x86_64.rpm \
#                    https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-9.noarch.rpm \
#  && dnf -y install ffmpeg libGL git wget python3-pip \
#  && dnf clean all

ENV WEIGHTS=flyingthings.pt
ENV BUILD_VER=0.0
ENV MODEL_CLASSES=flyingthings.yaml
ENV SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data
ENV BASEDIR=/opt/app-root/src
ENV MINIO_ENDPOINT=http://minio:9000
ENV MINIO_BUCKET=flyingthings
ENV MINIO_ACCESSKEY=minioadmin
ENV MINIO_SECRETKEY=minioadmin

RUN dnf install -y git wget libGL python3-pip \
 && dnf clean all

RUN mkdir -p $SIMPLEVIS_DATA \
 && chown -R 1001:1001 $SIMPLEVIS_DATA

WORKDIR /opt/app-root/src/

COPY requirements.txt ./
COPY get-model.sh ./
RUN pip install --no-cache-dir -r ./requirements.txt

COPY app/ ./

WORKDIR /opt/app-root/src

USER 1001
EXPOSE 8000

CMD ["/opt/app-root/src/get-model.sh"]
