# FROM quay.io/centos/centos:stream9
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER 0

ARG BUILD_VER=0.0
ENV BUILD_VER=${BUILD_VER}

# RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
#                    https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm \
#                    http://mirror.stream.centos.org/9-stream/CRB/x86_64/os/Packages/ladspa-1.13-28.el9.x86_64.rpm \
#                    https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-9.noarch.rpm \
#  && dnf -y git wget libGL python3-pip ffmpeg \
#  && dnf clean all

RUN dnf install -y epel-release && \
    /usr/bin/crb enable && \
    dnf install -y git wget libGL python3-pip ffmpeg-free && \
    dnf clean all
