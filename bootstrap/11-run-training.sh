#!/bin/bash

cd ../pipelines/manifests

tkn pipeline start run-training \
-p BATCH_SIZE="64" \
-p NUM_EPOCHS="100" \
--use-param-defaults --showlog
