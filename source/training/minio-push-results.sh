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

# Store previous training run in a variable and tag previous objects
PRIOR_TRAINING_RUN=$training_run_value
./mc --config-dir miniocfg tag set myminio/$MINIO_BUCKET/model_custom.pt "training-run=$PRIOR_TRAINING_RUN" --insecure
./mc --config-dir miniocfg tag set myminio/$MINIO_BUCKET/model_custom.torchscript "training-run=$PRIOR_TRAINING_RUN" --insecure
./mc --config-dir miniocfg tag set myminio/$MINIO_BUCKET/classes.txt "training-run=$PRIOR_TRAINING_RUN" --insecure

# Check if the value is null and set TRAINING_RUN_NUM accordingly
if [ "$training_run_value" = "null" ]; then
    TRAINING_RUN_NUM=0
else
    # If the value is not null, interpret it as a number and increment by 1
    TRAINING_RUN_NUM=$((training_run_value + 1))
fi
#padded_number=$(printf "%04d" "$TRAINING_RUN_NUM")
PADDED_NUMBER=$(printf "%04d" "$TRAINING_RUN_NUM")
echo "This training run number: $PADDED_NUMBER"  


./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/training-results.tgz myminio/$MINIO_BUCKET/training-run-$PADDED_NUMBER/training-results.tgz --insecure
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/train/weights/best.pt myminio/$MINIO_BUCKET/training-run-$PADDED_NUMBER/$WEIGHTS --insecure
# TODO: Add a check to see if the training run was successful

./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/train/weights/best.pt myminio/$MINIO_BUCKET/model_custom_$PADDED_NUMBER.pt --insecure
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/train/weights/best.torchscript myminio/$MINIO_BUCKET/model_custom_$PADDED_NUMBER.torchscript --insecure
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/datasets/classes.txt myminio/$MINIO_BUCKET/classes_$PADDED_NUMBER.txt --insecure

# Set the training run for all objects
./mc --config-dir miniocfg tag set myminio/$MINIO_BUCKET/model_custom_$PADDED_NUMBER.pt "training-run=latest" --insecure
./mc --config-dir miniocfg tag set myminio/$MINIO_BUCKET/model_custom_$PADDED_NUMBER.torchscript "training-run=latest" --insecure
./mc --config-dir miniocfg tag set myminio/$MINIO_BUCKET/classes_$PADDED_NUMBER.txt "training-run=latest" --insecure