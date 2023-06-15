FROM quay.io/centos/centos:stream9

WORKDIR /opt/app-root/src
ARG WEIGHTS=yolov8n.pt
ARG BUILD_VER=0.0
ARG MODEL_CLASSES=coco128.yaml
ARG MINIO_ENDPOINT=minio-flyingthings-standalone.apps.ocpbare.davenet.local/flyingthings

RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
                   https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm \
                   http://mirror.stream.centos.org/9-stream/CRB/x86_64/os/Packages/ladspa-1.13-28.el9.x86_64.rpm \
                   https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-9.noarch.rpm \
 && dnf -y install ffmpeg libGL git wget python3-pip \
 && dnf clean all

RUN pip install --no-cache-dir ultralytics

ENV WEIGHTS=${WEIGHTS}
ENV BUILD_VER=${TRAINING_VER}
ENV MODEL_CLASSES=${MODEL_CLASSES}
ENV MINIO_ENDPOINT=${MINIO_ENDPOINT}
ENV SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data
ENV BASEDIR=/opt/app-root/src

RUN cd /opt/app-root/src \
 && curl -k "https://${MINIO_ENDPOINT}/${WEIGHTS}" -o ${WEIGHTS} \
 && curl -k "https://${MINIO_ENDPOINT}/${MODEL_CLASSES}" -o ${MODEL_CLASSES}

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./

#USER 1001
USER 0
EXPOSE 8000
ENTRYPOINT ["/usr/local/bin/uvicorn"]
CMD ["main:app", "--host", "0.0.0.0"]