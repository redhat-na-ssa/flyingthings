FROM registry.access.redhat.com/ubi9/python-39

USER 0

# version lock cuda
RUN dnf install -y 'dnf-command(versionlock)' && \
    dnf versionlock \
        libcudnn8-8.7.0.84-1.cuda11.8.x86_64 \
        libcudnn8-devel-8.7.0.84-1.cuda11.8.x86_64 \
        libnccl-devel-2.15.5-1+cuda11.8.x86_64 \
        libnccl-2.15.5-1+cuda11.8.x86_64

# upgrade all the things; add libGL
RUN dnf upgrade -y && \
    dnf install -y mesa-libGL && \
    dnf -y clean all

USER 1001

# install the pip things
RUN pip install --no-cache-dir \
    opencv-python==4.7.* \
    opencv-contrib-python==4.7.*