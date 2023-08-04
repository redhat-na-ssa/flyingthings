FROM quay.io/centos/centos:stream9

WORKDIR /opt/app-root/src
ARG YOLOv5_VERSION=7.0

RUN dnf install -y git wget libGL python3-pip \
 && dnf clean all

RUN mkdir -p /usr/local/lib/python3.9/site-packages \
 && cd /usr/local/lib/python3.9/site-packages \
 && git clone --branch v${YOLOv5_VERSION} --depth 1 https://github.com/ultralytics/yolov5.git \
 && pip install --no-cache-dir \
    -r /usr/local/lib/python3.9/site-packages/yolov5/requirements.txt \
 && rm -rf /usr/local/lib/python3.9/site-packages/yolov5/.git

WORKDIR /workspace

COPY source/yolo/requirements.txt ./

RUN pip install --no-cache-dir -r ./requirements.txt

USER 1001
WORKDIR /opt/app-root/src