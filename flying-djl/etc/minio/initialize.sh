sleep 10

mc alias set rht http://rht:9000/ $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

mc mb rht/flyingthings
mc policy set public rht/flyingthings
mc admin user add rht/ bucketwriter minio123

#mc mb rht/flyingthings/models
mc event add  rht/flyingthings/models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".txt"
mc event add  rht/flyingthings/models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".zip"
mc event add  rht/flyingthings/models arn:minio:sqs::MLNOTIFY:mqtt --event "put,delete" --suffix ".pt"

#mc mb rht/flyingthings/correctivecandidates
mc policy set public rht/flyingthings/correctivecandidates

mc admin service restart rht
