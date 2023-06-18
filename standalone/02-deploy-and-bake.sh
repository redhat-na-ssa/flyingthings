#!/bin/bash

nbpod=`oc get po|grep -v NAME|grep flyingthings-notebook|awk '{ print $1 }'`
oc cp ../notebooks/01-training-prep.ipynb $nbpod:/opt/app-root/src/
oc cp ../notebooks/02-object-detect-train.ipynb $nbpod:/opt/app-root/src/
oc cp ../notebooks/99-utils.ipynb $nbpod:/opt/app-root/src/

# # Specify the Jupyter Notebook server URL and API token
# JUPYTER_SERVER="http://flyingthings-rt-flyingthings-standalone.apps.ocpbare.davenet.local"
# API_TOKEN="0548aeb5bc2c275cc7d36e38a998ce6677f514564f3d0bde"

# # Specify the notebook file name
# NOTEBOOK_FILE="/opt/app-root/src/01-training-prep.ipynb"

# # Execute all the cells in the notebook
# execute_notebook() {
#     curl -X POST -H "Authorization: token $API_TOKEN" \
#         "$JUPYTER_SERVER/api/notebooks/$NOTEBOOK_FILE/execute"
# }

# # Call the function to execute the notebook
# execute_notebook
