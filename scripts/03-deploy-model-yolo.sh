#!/bin/bash

# get_namespace(){
#   NAMESPACE=$(oc project -q 2>/dev/null)
#   echo "NAMESPACE: ${NAMESPACE}"
#   echo ""
# }

MENDPOINT=$(oc get route|grep minio|grep -v console|awk '{ print $2 }')
MINIO_ENDPOINT=https://$MENDPOINT
MINIO_BUCKET=yolo
MINIO_ACCESSKEY=minioadmin
MINIO_SECRETKEY=minioadmin
MODEL_IMAGE=$(oc get is|grep yolo-api|awk '{ print $2 }')
MODEL_NAME=model-yolo

echo "Deploying default yolo model"
echo "MINIO_ENDPOINT: ${MINIO_ENDPOINT}"
echo "MINIO_BUCKET: ${MINIO_BUCKET}"
echo "MINIO_ACCESSKEY: ${MINIO_ACCESSKEY}"
echo "MINIO_SECRETKEY: ${MINIO_SECRETKEY}"
echo "MODEL_IMAGE: ${MODEL_IMAGE}"
echo "MODEL_NAME: ${MODEL_NAME}"

oc new-app "${MODEL_IMAGE}" \
  --name="${MODEL_NAME}" \
  --env=WEIGHTS=model_custom.pt \
  --env=MINIO_ENDPOINT="${MINIO_ENDPOINT}" \
  --env=MINIO_BUCKET="${MINIO_BUCKET}" \
  --env=MINIO_ACCESSKEY="${MINIO_ACCESSKEY}" \
  --env=MINIO_SECRETKEY="${MINIO_SECRETKEY}"

oc apply -f - <<EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${MODEL_NAME}
  labels:
    app: ${MODEL_NAME}
    app.kubernetes.io/component: ${MODEL_NAME}
    app.kubernetes.io/instance: ${MODEL_NAME}
annotations:
  openshift.io/host.generated: "true"
spec:
  to:
    kind: Service
    name: ${MODEL_NAME}
    weight: 100
  port:
    targetPort: 8080-tcp
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Allow
EOF
exit 0
