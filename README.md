---
layout: llm-serve
title: llm-serve
keywords: overview,introduction
---

# llm-serve

This is an example repository containing minimal code to setup and serve an LLM (Gemma class)
on owned infrastructure using GCP and Ray.

### How to run

In the most basic scenario, you can use:

```sh
gcloud auth login
gcloud config set project llm-serve-112
gcloud auth application-default login

gcloud container clusters get-credentials testing-serving-gcp-us-central1 --zone us-central1

# terraform new workspace testing

terraform init
terraform plan
terraform apply
```

# Helpful Debbugging Commands

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

## Test the Serving API

```sh
curl -X POST http://localhost:8000 \
  -H "Content-Type: application/json" \
  -d '{"text": "Complete this sentence: (return one word only)"}'

```


### Running locally

```
docker pull anyscale/ray-llm:0.5.0
```

### Google Cloud Resources

| Resource              | Google Name/Location  |
| --------------------- | ----------------------|
| Project Home          | [`llm-serve-423918`](https://console.cloud.google.com/home/dashboard?folder=&organizationId=&project=llm-serve-423918)|
