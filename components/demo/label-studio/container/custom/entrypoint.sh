#!/bin/sh
source env/bin/activate
cd /opt/app-root/src/.local

# Download the label studio export from google drive
mkdir -p /opt/app-root/src/.local/share
cd /opt/app-root/src/.local/share
fileid="16qq4YFPmU2rQ7ZPRfqL0oBmOCz_Dnbp7"
filename="label-studio.tar.gz"
curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${fileid}" -o ${filename}
tar xzf label-studio.tar.gz
cd /opt/app-root/src/
label-studio