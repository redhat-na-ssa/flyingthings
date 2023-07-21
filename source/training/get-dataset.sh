#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
./mc --config-dir miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/$DATASET_ZIP $DATASET_ZIP --insecure

mkdir -p $SIMPLEVIS_DATA/workspace/datasets
cd $SIMPLEVIS_DATA/workspace/datasets
unzip $SIMPLEVIS_DATA/workspace/$DATASET_ZIP
ls -l $SIMPLEVIS_DATA/workspace/datasets

# Check if the file exists in the bucket
cd $SIMPLEVIS_DATA/workspace
if ./mc ls myminio/$MINIO_BUCKET/training-run.txt &> /dev/null; then
    echo "File exists. Downloading..."
    # Download the file
    ./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/training-run.txt $SIMPLEVIS_DATA/workspace/
else
    echo "File does not exist. Creating..."
    # Create the file in the bucket
    echo "0">training-run.txt
    ls -al
    ./mc --config-dir miniocfg cp training-run.txt myminio/$MINIO_BUCKET/training-run.txt
fi

