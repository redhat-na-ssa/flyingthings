# Notes

## TODO

- [ ] Review configuration of label studio
  - Move artifacts to git repo?
- [ ] Review training pipeline GPU task parameters
- [ ] Review tekton tasks
- [ ] Make task `upload-artifacts` more generic
- [ ] Update to use demo catalog for `00-setup-components.sh`
- [ ] Update to use demo catalog for `bootstrap.sh`
  - [ ] Check for `helm`; install helm

### label-studio login

user: user1@example.com
pass: password1

### patch bc for branch testing

```
  oc patch bc \
    -n ml-demo \
    label-studio-s2i \
    --patch '[{"op": "add", "path": "/spec/source/git/ref", "value": "gitops-catalog" }]' --type=json

  oc patch bc \
    -n ml-demo \
    python-custom-39 \
    --patch '[{"op": "add", "path": "/spec/source/git/ref", "value": "gitops-catalog" }]' --type=json

  oc patch bc \
    -n ml-demo \
    yolo-api-source-ubi \
    --patch '[{"op": "add", "path": "/spec/source/git/ref", "value": "gitops-catalog" }]' --type=json
```
