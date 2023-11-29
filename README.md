# Computer vision demo

[![File Linting](https://github.com/redhat-na-ssa/flyingthings/actions/workflows/linting.yaml/badge.svg)](https://github.com/redhat-na-ssa/flyingthings/actions/workflows/linting.yaml)

This workshop is designed to showcase OpenShift as a platform for developing and operationalizing AI/ML applications. It uses many tools in the Red Hat ecosystem as well as 3rd party applications and services. This particular workshop features a computer vision implementation and covers a workflow for custom training and serving for integration with other applications and services.

I've created a video series explaining the workshop and a runthrough of the setup and use cases here.
[![WorkshopSeries](docs/images/youtube-channel.png)](https://youtu.be/agL8PrEPFR8?si=AL0G352nzrH2mfjP)

## Prerequisites

- Nvidia GPU hardware
- OpenShift 4.12+ w/ cluster admin
- AWS (auto scaling, optional)
- OpenShift Dev Spaces 3.8.0+ (optional)
- Internet access

Red Hat Demo Platform Catalog (RHDP) options:

- `MLOps Demo: Data Science & Edge Practice`
- `Red Hat OpenShift Container Platform 4 Demo`

## Quickstart

```
# cluster tasks
scripts/bootstrap.sh

# namespace tasks
scripts/01-setup-pipelines.sh
scripts/02-run-train-model.sh
```

## Workshop Instructions

See [WORKSHOP.md](docs/WORKSHOP.md)
