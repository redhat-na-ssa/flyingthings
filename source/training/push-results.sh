#!/bin/bash
cd /opt/app-root/src/simplevis-data/
echo "*************** Training Run Results*************************"
cat /opt/app-root/src/simplevis-data/runs/detect/train/results.csv
echo "************************************************************"
tar czf training-results.tgz /opt/app-root/src/simplevis-data/runs/detect/train/
./mc --config-dir miniocfg cp training-results.tgz myminio/flyingthings/training-results.tgz --insecure
./mc --config-dir miniocfg cp /opt/app-root/src/simplevis-data/runs/detect/train/weights/best.pt myminio/flyingthings/model_custom.pt --insecure