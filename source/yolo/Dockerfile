FROM quay.io/centos/centos:stream9

WORKDIR /workspace/source/yolo

RUN dnf install -y git wget libGL python3-pip \
 && dnf clean all

RUN pip install --no-cache-dir ultralytics

COPY requirements.txt /workspace/source/yolo/requirements.txt

RUN pip install --no-cache-dir -r /workspace/source/yolo/requirements.txt

USER 1001
WORKDIR /opt/app-root/src