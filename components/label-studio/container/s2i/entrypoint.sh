#!/bin/bash
set -e

kludge_to_newest(){
  label-studio version
  pip install --no-cache -U label-studio -q
}

kludge_to_newest

exec "$@"
