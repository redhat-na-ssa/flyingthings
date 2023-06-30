ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# FROM image-registry.openshift-image-registry.svc:5000/flyingthings-standalone/yolo:latest
# FROM quay.io/centos/centos:stream9

USER 0

WORKDIR /opt/app-root/src

ENV BATCH_SIZE=2
ENV NUM_EPOCHS=1
ENV WEIGHTS=flyingthings.pt
ENV BASE_MODEL=model_pretrained.pt
ENV MODEL_CLASSES=flyingthings.yaml
ENV MINIO_ENDPOINT=http://minio:9000
ENV DATASET_ZIP=flyingthings-yolo.zip
ENV SIMPLEVIS_DATA=/opt/app-root/src/simplevis-data
ENV BASEDIR=/opt/app-root/src
ENV MINIO_BUCKET=flyingthings
ENV MINIO_ACCESSKEY=minioadmin
ENV MINIO_SECRETKEY=minioadmin
ENV MINIO_CLIENT_URL=https://dl.min.io/client/mc/release/linux-amd64

RUN mkdir -p ${SIMPLEVIS_DATA} \
 && dnf install -y unzip tree \
 && dnf clean all

WORKDIR ${SIMPLEVIS_DATA}
RUN curl $MINIO_CLIENT_URL/mc -o mc \
 && chmod +x mc \
 && ./mc --config-dir miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure \
 && ./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$MODEL_CLASSES $MODEL_CLASSES --insecure \
 && ./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$WEIGHTS $WEIGHTS --insecure \
 && ./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$BASE_MODEL $BASE_MODEL --insecure \
 && ./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$DATASET_ZIP $DATASET_ZIP --insecure

COPY dataprep.sh ${SIMPLEVIS_DATA}/

COPY distribute-files.py ${SIMPLEVIS_DATA}/

COPY push-results.sh ${SIMPLEVIS_DATA}/

COPY run-training.sh ${SIMPLEVIS_DATA}/

RUN chown -R 1001:1001 ${SIMPLEVIS_DATA}

USER 1001

WORKDIR ${SIMPLEVIS_DATA}
# CMD ["yolo", "train", "model=yolov8n.pt", "batch=2", "epochs=1", "data=flyingthings.yaml", "exist_ok=True"]