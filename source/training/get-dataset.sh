#!/bin/bash
cd $SIMPLEVIS_DATA/workspace
curl $MINIO_CLIENT_URL/mc -o mc
chmod +x mc
mc_exe = $SIMPLEVIS_DATA/workspace/mc
$mc_exe --config-dir miniocfg config host add myminio $MINIO_ENDPOINT $MINIO_ACCESSKEY $MINIO_SECRETKEY --insecure
$mc_exe --config-dir miniocfg cp myminio/$MINIO_BUCKET/$DATASET_ZIP $DATASET_ZIP --insecure

mkdir -p $SIMPLEVIS_DATA/workspace/datasets
cd $SIMPLEVIS_DATA/workspace/datasets
unzip $SIMPLEVIS_DATA/workspace/$DATASET_ZIP
ls -l $SIMPLEVIS_DATA/workspace/datasets

# Check if the file exists in the bucket
if $mc_exe ls myminio/$MINIO_BUCKET/training-run.txt &> /dev/null; then
    echo "File exists. Downloading..."
    # Download the file
    $mc_exe cp myminio/$MINIO_BUCKET/training-run.txt $SIMPLEVIS_DATA/workspace/
else
    echo "File does not exist. Creating..."
    # Create the file in the bucket
    echo "0" > training-run.txt
    $mc_exe cp training-run.txt myminio/$MINIO_BUCKET/training-run.txt
fi

