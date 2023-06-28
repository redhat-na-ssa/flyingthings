#!/bin/bash
oc new-build --name base-ubi9 --strategy docker --binary --context-dir .
oc start-build base-ubi9 --from-dir ubi9 --follow

oc new-build --name minimal-notebook --strategy docker --binary --image-stream base-ubi9:latest --context-dir .
oc start-build minimal-notebook --from-dir minimal/py39 --follow

oc new-build --name yolo-notebook --strategy docker --binary --image-stream minimal-notebook:latest --context-dir .
oc start-build yolo-notebook --from-dir yolo-notebook --follow

oc new-build --name yolo --strategy docker --binary --context-dir .
oc start-build yolo --from-dir yolo --follow

oc new-build --name model-server --strategy docker --binary --context-dir .
oc start-build model-server --from-dir model --follow

oc new-build --name training-job --strategy docker --binary --context-dir .
oc start-build training-job --from-dir training-job --follow