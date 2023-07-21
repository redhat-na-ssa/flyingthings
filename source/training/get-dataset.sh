#!/bin/bash

# Function to parse the numeric value from the input line
parse_numeric_value() {
  # Using grep to extract the numeric value from the line
  # This assumes that the numeric value is the only number in the line
  # You can modify this regex pattern based on your specific input format
  local numeric_value=$(echo "$1" | grep -Eo '[0-9]+')

  echo "$numeric_value"
}

# Function to increase the numeric value by 1
increase_value_by_one() {
  local increased_value=$(( $1 + 1 ))
  echo "$increased_value"
}

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
if ./mc --config-dir miniocfg ls myminio/$MINIO_BUCKET/training-run.txt &> /dev/null; then
    echo "File exists. Downloading..."
    # Download the file
    ./mc --config-dir miniocfg cp myminio/$MINIO_BUCKET/training-run.txt $SIMPLEVIS_DATA/workspace/

    # Read the single line from the text file
    input_file="$SIMPLEVIS_DATA/workspace/training-run.txt"

    if [ -f "$input_file" ]; then
    read -r input_line < "$input_file"

    # Parse the numeric value from the line
    numeric_value=$(parse_numeric_value "$input_line")
    echo "Numeric value: $numeric_value"

    # Increase the value by 1
    increased_value=$(increase_value_by_one "$numeric_value")
    echo "Training run number: $increased_value"
    rm training-run.txt
    echo $increased_value>training-run.txt
    ls -al
    ./mc --config-dir miniocfg cp training-run.txt myminio/$MINIO_BUCKET/training-run.txt    
    else
    echo "Error: File '$input_file' not found."
    fi

else
    echo "File does not exist. Creating..."
    # Create the file in the bucket
    echo "0">training-run.txt
    ls -al
    ./mc --config-dir miniocfg cp training-run.txt myminio/$MINIO_BUCKET/training-run.txt
fi
