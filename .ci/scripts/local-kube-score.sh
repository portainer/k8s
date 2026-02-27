#!/bin/bash

helm template charts/portainer -f .ci/values-kube-score.yaml --no-hooks | kube-score score -
