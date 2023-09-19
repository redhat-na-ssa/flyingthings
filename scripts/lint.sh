#!/bin/bash
# shellcheck disable=SC2015,SC1091
set -e

usage(){
  echo "
  usage: scripts/lint.sh
  "
}

py_setup_venv(){
  python3 -m venv venv
  source venv/bin/activate
  pip install -q -U pip

  py_check_venv || usage
}

py_check_venv(){
  # activate python venv
  [ -d venv ] && . venv/bin/activate || py_setup_venv
  [ -e requirements.txt ] && pip install -q -r requirements.txt
}

py_check_bins(){
  which python || exit 0
  which pip || exit 0
}

reset_wordlist(){
  pyspelling | sort -u | grep -E -v ' |---|/|^$' > .wordlist-md
}

# activate python venv
py_check_venv

# chcek scripts
which shellcheck && \
  shellcheck scripts/*.sh && \
  shellcheck source/training/*.sh

# check spelling
which aspell && \
pyspelling -c .pyspelling.yml

# check yaml
yamllint . && echo "YAML check passed :)"

# validate manifests
[ -e scripts/validate_manifests.sh ] && scripts/validate_manifests.sh
