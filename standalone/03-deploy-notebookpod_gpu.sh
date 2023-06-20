#!/bin/bash
oc project flyingthings-standalone
oc apply -k notebook-gpus
