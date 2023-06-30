#!/bin/bash
oc project flyingthings-standalone
cd ../source
oc apply -k notebook-gpus
