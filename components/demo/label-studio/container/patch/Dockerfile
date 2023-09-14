FROM docker.io/heartexlabs/label-studio:ubi_latest

ENV DEBUG=true

# update: label-studio version
RUN pip install --no-cache -U \
      label-studio pip

# fix: permission issues

# fix: needed to address data writes
# recommend: chmod g+rw id=0 for writeable areas in image 
# RUN mkdir -p /label-studio/.local && \
#     chmod g+rw \
#       /label-studio/data \
#       /label-studio/.local

# fix: remove path that is a volume
RUN rm -rf /label-studio/data

# fix: add volumes
VOLUME /label-studio/.local
VOLUME /label-studio/data
