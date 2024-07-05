# Notes

## TODO

- [ ] Review configuration of label studio
  - Move artifacts to git repo?
- [ ] Review tekton tasks
- [ ] Make task `upload-artifacts` more generic
  - [ ] Review https://github.com/HumanSignal/label-studio-sdk/blob/master/examples/migrate_ls_to_ls/README.md

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
