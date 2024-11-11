# adhoc-ops

## Purpose

You ~~are lazy~~ want to avoid running imperative commands on the local command line to setup your cluster.

This component has been tested using AWS based OpenShift instances provisioned by [demo.redhat.com](https://demo.redhat.com).

NOTE: The creates a service account with `cluster-admin` - DO NOT DO THIS IN PRODUCTION! Setup specific roles for a task

## Usage

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - base

components:
  - 00-job
  - 01-job
```
