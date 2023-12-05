#!/bin/bash
set -e

kludge_to_newest(){
  label-studio version
  
  echo "kludging ahead to newest version..."
  pip install --no-cache -U label-studio -q
  
  label-studio version
}

kludge_to_newest

exec "$@"
