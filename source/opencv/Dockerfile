FROM quay.io/modh/cuda-notebooks:cuda-jupyter-tensorflow-ubi9-python-3.9-2023a-weekly

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
    elyra==3.* \
    opencv-python==4.7.* \
    opencv-contrib-python==4.7.* \
    matplotlib==3.6.* \
    protobuf==3.19.* \
    imutils==0.5.* \
    tensorflow_datasets==4.9.* \
    keras_tuner==1.0.* \
    visualkeras==0.0.* \
    graphviz==0.20.* \
    pydot==1.4.* \
    python-dotenv==1.*