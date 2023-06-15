#!/bin/bash
oc delete -k notebook
oc delete -k minio
oc delete cm flyingthings-configmap