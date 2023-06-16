#!/bin/bash
oc new-build --name yolo --strategy docker --binary --context-dir .
oc start-build yolo --from-dir yolo --follow

oc new-build --name flyingthings-model --strategy docker --binary --image-stream yolo:latest --context-dir .
oc start-build flyingthings-model --from-dir model --follow
