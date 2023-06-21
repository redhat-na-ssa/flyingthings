#!/bin/bash
oc project flyingthings-standalone
oc new-build --name yolo --strategy docker --binary --context-dir .
oc start-build yolo --from-dir yolo --follow

oc new-build --name custom-model --strategy docker --binary --image-stream yolo:latest --env="WEIGHTS=model_custom.pt" --context-dir .
oc start-build custom-model --from-dir model --follow

oc new-build --name coco-model --strategy docker --binary --image-stream yolo:latest --env="WEIGHTS=model_pretrained.pt" --context-dir .
oc start-build coco-model --from-dir model --follow