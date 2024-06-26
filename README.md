---
layout: llm-serve
title: llm-serve
keywords: overview,introduction
---

# llm-serve

A simple demonstration setting up minimal infra to serve an LLM(Gemma 7B) on
user owned infrastructure using Google Cloud and Ray primitives.

### How to run

In the most basic scenario, you can use:

```sh
gcloud auth login
gcloud config set project llm-serve-112
gcloud auth application-default login

gcloud container clusters get-credentials testing-serving-gcp-us-central1 --zone us-central1

terraform init
terraform plan
terraform apply

./tools/port-forward.py   # port forward all services (must be created and online)
```

### Helpful Debbugging Commands

```sh
k get raycluster -n ray
k describe raycluster -n ray

# get into head node:
export HEAD_POD=$(kubectl get pods --selector=ray.io/node-type=head -n ray -o custom-columns=POD:metadata.name --no-headers)

k describe -n ray pod $HEAD_POD
k exec -n ray -it $HEAD_POD -- ray status
k exec -n ray -it $HEAD_POD -- ray list actors

k exec -n ray -it $HEAD_POD /bin/bash
# => serve run model:entrypoint

# show rayservice
k describe rayservice google-recurrentgemma-2b-it-model-server -n ray

# latest serve logs
k exec -it $HEAD_POD -n ray -- ls -lah /tmp/ray/session_latest/logs/serve

# Get status of serving container:
kubectl exec -n ray -it $HEAD_POD -- serve status

# show model in ray namespace
k describe cm google-recurrentgemma-2b-it-model-server -n ray

```

## Test the Inference/Serving API

```sh
curl -X POST http://localhost:8000 \
  -H "Content-Type: application/json" \
  -d '{"text": "Im going to say hello, you should return: (one word only)"}'

```

### Google Cloud Resources

| Resource              | Google Name/Location  |
| --------------------- | ----------------------|
| Project Home          | [`llm-serve-423918`](https://console.cloud.google.com/home/dashboard?folder=&organizationId=&project=llm-serve-423918)|
