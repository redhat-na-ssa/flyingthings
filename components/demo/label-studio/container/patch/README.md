# docker.io/heartexlabs/label-studio:ubi_latest

## Build

```
podman build -t label-studio:patched .

podman run --rm -p 8080:8080 label-studio:patched
```

Open [http://localhost:8080](http://localhost:8080)
