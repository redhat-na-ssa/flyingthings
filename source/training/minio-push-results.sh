#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
echo "*************** Training Run Results*************************"
cat $SIMPLEVIS_DATA/workspace/runs/train/results.csv
echo "************************************************************"
tar czf $SIMPLEVIS_DATA/workspace/runs/training-results.tgz $SIMPLEVIS_DATA/workspace/runs/train/
ls -l $SIMPLEVIS_DATA

echo "trainingrun: $trainingrun"
./mc --config-dir miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure

# Get previous training run if it exists, otherwise set it to 0
TRAINING_RUN_NUM=0
TRAINING_RUN=$(./mc --config-dir miniocfg tag list --json myminio/$MINIO_BUCKET/model_custom.pt --insecure)
training_run_value=$(echo "$TRAINING_RUN" | jq -r '.tagset."training-run"')
echo "Previous training-run: $training_run_value"

# Check if the value is null and set TRAINING_RUN_NUM accordingly
if [ "$training_run_value" = "null" ]; then
    TRAINING_RUN_NUM=0
else
    # If the value is not null, interpret it as a number and increment by 1
    TRAINING_RUN_NUM=$((training_run_value + 1))
fi
echo "This training run number: $TRAINING_RUN_NUM"  


./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/training-results.tgz myminio/$MINIO_BUCKET/training-run-$TRAINING_RUN_NUM/training-results.tgz --insecure
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/train/weights/best.pt myminio/$MINIO_BUCKET/training-run-$TRAINING_RUN_NUM/$WEIGHTS --insecure
# TODO: Add a check to see if the training run was successful
# TODO: modify model deployment to use name of new model
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/train/weights/best.pt myminio/$MINIO_BUCKET/model_custom.pt --insecure
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/train/weights/best.torchscript myminio/$MINIO_BUCKET/model_custom.torchscript --insecure

# Set the training run for all objects
./mc --config-dir miniocfg tag set myminio/$MINIO_BUCKET/model_custom.pt "training-run=$TRAINING_RUN_NUM" --insecure
./mc --config-dir miniocfg tag set myminio/$MINIO_BUCKET/model_custom.torchscript "training-run=$TRAINING_RUN_NUM" --insecure