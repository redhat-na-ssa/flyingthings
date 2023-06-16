FROM quay.io/centos/centos:stream9

WORKDIR /opt/app-root/src

RUN dnf install -y git wget libGL python3-pip \
 && dnf clean all

RUN pip install --no-cache-dir ultralytics

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

USER 1001