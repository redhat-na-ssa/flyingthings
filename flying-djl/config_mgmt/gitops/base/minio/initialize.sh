sleep 10

mc --config-dir /data alias set rht http://minio:9000/ $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
mc --config-dir /data mb rht/flyingthings-models
mc --config-dir /data policy set public rht/flyingthings-models
mc --config-dir /data admin user add rht/ bucketwriter minio123

mc --config-dir /data event add  rht/flyingthings-models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".txt"
mc --config-dir /data event add  rht/flyingthings-models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".zip"
mc --config-dir /data event add  rht/flyingthings-models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".pt"

mc mb rht/flyingthings-correctiveCandidates
mc policy set public rht/flyingthings-correctiveCandidates

mc --config-dir /data admin service restart rht
