#!/bin/bash
oc project flyingthings-standalone
oc new-build --name yolo --strategy docker --binary --context-dir .
oc start-build yolo --from-dir yolo --follow

oc new-build --name flyingthings-training --strategy docker --binary --context-dir .
oc start-build flyingthings-training --from-dir training --follow

oc new-build --name training-job --strategy docker --binary --context-dir .
oc start-build training-job --from-dir training-job --follow