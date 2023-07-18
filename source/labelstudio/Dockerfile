FROM registry.access.redhat.com/ubi9/python-39

RUN set -x && \
    python3 -m venv env && \
    source env/bin/activate && \
    python -m pip install label-studio

COPY entrypoint.sh .

EXPOSE 8080

ENTRYPOINT [ "./entrypoint.sh" ]