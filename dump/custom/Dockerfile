ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER 0
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
                   https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm \
                   http://mirror.stream.centos.org/9-stream/CRB/x86_64/os/Packages/ladspa-1.13-28.el9.x86_64.rpm \
                   https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-9.noarch.rpm \
 && dnf -y install libGL \
 && dnf clean all

RUN pip install --no-cache-dir Pillow==9.5.0 ipython==8.10.0 ipython-genutils==0.2.0 ultralytics==8.0.124
