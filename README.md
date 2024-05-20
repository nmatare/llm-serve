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
gcloud config set project llm-serve-423918
gcloud auth application-default login

# terraform new workspace testing

terraform init
terraform plan
terraform apply
```

### Google Cloud Resources

| Resource              | Google Name/Location  |
| --------------------- | ----------------------|
| Project Home          | [`llm-serve-423918`](https://console.cloud.google.com/home/dashboard?folder=&organizationId=&project=llm-serve-423918)|
