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

ENV WEIGHTS=yolov8n.pt
ENV BUILD_VER=0.0
ENV MODEL_CLASSES=flyingthings.yaml
ENV SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data
ENV BASEDIR=/opt/app-root/src
ENV MINIO_ENDPOINT=http://minio:9000
ENV MINIO_BUCKET=flyingthings
ENV MINIO_ACCESSKEY=minioadmin
ENV MINIO_SECRETKEY=minioadmin

# RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc \
#  && chmod +x mc \
#  && ./mc config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure \
#  && ./mc cp myminio/$MINIO_BUCKET/$MODEL_CLASSES $MODEL_CLASSES --insecure \
#  && ./mc cp myminio/$MINIO_BUCKET/$WEIGHTS $WEIGHTS --insecure \
#  && rm ./mc

RUN dnf install -y git wget libGL python3-pip \
 && dnf clean all

# RUN pip install --no-cache-dir ultralytics==8.0.124

RUN mkdir -p $SIMPLEVIS_DATA \
 && chown -R 1001:1001 $SIMPLEVIS_DATA

WORKDIR /opt/app-root/src/

COPY source/model/requirements.txt ./
COPY source/model/get-model.sh ./
RUN pip install --no-cache-dir -r ./requirements.txt

COPY source/model/app/ ./

WORKDIR /opt/app-root/src

USER 1001
EXPOSE 8000
# ENTRYPOINT ["/usr/local/bin/uvicorn"]
# CMD ["main:app", "--host", "0.0.0.0"]
CMD ["/opt/app-root/src/get-model.sh"]
# ENTRYPOINT [ "tail", "-f", "/dev/null" ]