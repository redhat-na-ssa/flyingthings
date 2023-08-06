#!/bin/bash
source env/bin/activate
cd /opt/app-root/src/.local

# Download the label studio export from google drive
fileid="1gFT2sRdipkWOpxVnnzsWNcT3USB3LMNe"
filename="label-studio.tar.gz"
curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" > /dev/null
curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${fileid}" -o ${filename}
tar xzf label-studio.tar.gz
label-studio