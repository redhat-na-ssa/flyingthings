#!/bin/bash
oc new-build --name flyingthings-model --strategy docker --binary --context-dir .
oc start-build flyingthings-model --from-dir model --follow