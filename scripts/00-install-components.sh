#!/bin/sh

setup_minio(){
  oc apply -k components/demo/minio
}

setup_minio