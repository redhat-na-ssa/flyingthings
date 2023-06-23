FROM nexus.davenet.local:8082/repository/odh/yolo:latest
# FROM quay.io/centos/centos:stream9

USER 0
WORKDIR /opt/app-root/src
ARG WEIGHTS=flyingthings.pt
ARG MODEL_CLASSES=flyingthings.yaml
ARG MINIO_ENDPOINT=minio-flyingthings-standalone.apps.ocpbare.davenet.local/flyingthings
ARG SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data
ARG DATASET_ZIP=flyingthings-yolo.zip

ENV WEIGHTS=${WEIGHTS}
ENV MODEL_CLASSES=${MODEL_CLASSES}
ENV MINIO_ENDPOINT=${MINIO_ENDPOINT}
ENV DATASET_ZIP=${DATASET_ZIP}
ENV SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data
ENV BASEDIR=/opt/app-root/src
ENV MINIO_ENDPOINT=https://minio-flyingthings-standalone.apps.ocpbare.davenet.local
ENV MINIO_BUCKET=flyingthings
ENV MINIO_ACCESSKEY=minioadmin
ENV MINIO_SECRETKEY=minioadmin

RUN mkdir -p ${SIMPLEVIS_DATA} \
 && dnf install -y unzip tree \
 && dnf clean all

WORKDIR ${SIMPLEVIS_DATA}
RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc \
 && chmod +x mc \
 && ./mc --config-dir miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure \
 && ./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$MODEL_CLASSES $MODEL_CLASSES --insecure \
 && ./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$WEIGHTS $WEIGHTS --insecure \
 && ./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$DATASET_ZIP $DATASET_ZIP --insecure

COPY dataprep.sh ${SIMPLEVIS_DATA}/

COPY distribute-files.py ${SIMPLEVIS_DATA}/datasets/

COPY push-results.sh ${SIMPLEVIS_DATA}/

RUN chown -R 1001:1001 ${SIMPLEVIS_DATA}

USER 1001

# CMD ["yolo", "train", "model=yolov8n.pt", "batch=2", "epochs=1", "data=flyingthings.yaml", "exist_ok=True"]