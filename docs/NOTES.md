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

Run csi plugins on GPU nodes

```sh
cat << YAML > /tmp/patch.yaml
spec:
  placement:
    csi-plugin:
      tolerations:
        - key: nvidia.com/gpu
          operator: Exists
          effect: NoSchedule
YAML

oc -n openshift-storage \
  patch storagecluster \
  ocs-storagecluster \
  --type=merge \
  --patch "$(cat /tmp/patch.yaml)"
```
