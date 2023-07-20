sleep 10

mc alias set rht http://rht:9000/ $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
mc mb rht/djl-fprint-models
mc policy set public rht/djl-fprint-models
mc admin user add rht/ bucketwriter minio123

mc event add  rht/djl-fprint-models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".txt"
mc event add  rht/djl-fprint-models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".zip"
mc event add  rht/djl-fprint-models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".pt"

mc admin service restart rht
