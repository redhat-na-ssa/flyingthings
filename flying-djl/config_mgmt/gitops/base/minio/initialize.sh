#!/bin/bash

sleep 15 

mc --config-dir /tmp alias set rht http://localhost:9000/ "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

mc --config-dir /tmp mb rht/flyingthings
mc --config-dir /tmp policy set public rht/flyingthings
mc --config-dir /tmp admin user add rht/ bucketwriter minio123

mc --config-dir /tmp event add  rht/flyingthings/models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".txt"
mc --config-dir /tmp event add  rht/flyingthings/models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".zip"
mc --config-dir /tmp event add  rht/flyingthings/models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".pt"

mc --config-dir /tmp policy set public rht/flyingthings/correctivecandidates

mc --config-dir /tmp admin service restart rht
