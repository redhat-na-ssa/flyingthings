#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
echo "*************** Training Run Results*************************"
cat $SIMPLEVIS_DATA/workspace/runs/train/results.csv
echo "************************************************************"
tar czf $SIMPLEVIS_DATA/workspace/runs/training-results.tgz $SIMPLEVIS_DATA/workspace/runs/train/
ls -l $SIMPLEVIS_DATA

echo "trainingrun: $trainingrun"
./mc --config-dir miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure

PREVIOUS_RUN=0000
CURRENT_RUN=0000

# Get previous training run if it exists, otherwise set it to 0
# First, list all objects with the tag "training-run=latest"
LATEST_MOD_FILES=$(./mc --config-dir miniocfg find myminio/$MINIO_BUCKET --tags "training-run=latest" --insecure)

# Check if any objects are returned
if [ -n "$LATEST_MOD_FILES" ]; then
    first_file="${LATEST_MOD_FILES[0]}"

    # Get the file extension using parameter expansion
    # This will extract everything after the last dot (.) in the filename
    file_extension="${first_file##*_}"
    run_number="${file_extension%.*}"

    echo "First file: $first_file"
    echo "File extension: $file_extension"
    echo "Run number: $run_number"
    PREVIOUS_RUN=$run_number
    RUN_VALUE=$((run_number + 1))
    CURRENT_RUN=$(printf "%04d" "$RUN_VALUE")

    # Tag the previous run files with the previous run number
    for file in $LATEST_MOD_FILES; do
    echo "$COMMAND $file"
        ./mc --config-dir miniocfg tag set $file "training-run=$PREVIOUS_RUN" --insecure
    done
else
  echo "No files found."
fi
echo "Current run: $CURRENT_RUN"

# Push the results to minio
# Push the training results to a training run folder
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/training-results.tgz myminio/$MINIO_BUCKET/training-run-$CURRENT_RUN/training-results.tgz --insecure
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/train/weights/best.pt myminio/$MINIO_BUCKET/training-run-$CURRENT_RUN/$WEIGHTS --insecure

# Push the latest model files to the root of the bucket
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/train/weights/best.pt myminio/$MINIO_BUCKET/model_custom_$CURRENT_RUN.pt --insecure
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/runs/train/weights/best.torchscript myminio/$MINIO_BUCKET/model_custom_$CURRENT_RUN.torchscript --insecure
./mc --config-dir miniocfg cp $SIMPLEVIS_DATA/workspace/datasets/classes.txt myminio/$MINIO_BUCKET/classes_$CURRENT_RUN.txt --insecure

# Set the training run tag to latest
./mc --config-dir miniocfg tag set myminio/$MINIO_BUCKET/model_custom_$CURRENT_RUN.pt "training-run=latest" --insecure
./mc --config-dir miniocfg tag set myminio/$MINIO_BUCKET/model_custom_$CURRENT_RUN.torchscript "training-run=latest" --insecure
./mc --config-dir miniocfg tag set myminio/$MINIO_BUCKET/classes_$CURRENT_RUN.txt "training-run=latest" --insecure