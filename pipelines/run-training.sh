#!/bin/bash

# Check the number of arguments
if [ "$#" -ne 2 ]; then
  echo "Error: Expected 2 arguments, but received $# arguments."
  echo "Usage: $0 BATCHSIZE NUM_EPOCHS"
  exit 1
fi

BATCHSIZE=$1
NUM_EPOCHS=$2

tkn pipeline start training-pipeline \
-p batch-size=$BATCHSIZE \
-p num-epochs=$NUM_EPOCHS --showlog