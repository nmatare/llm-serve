---
template: reveal.html
---

# Serving LLMs on Ray

##### Zero to 40B Parameter Hero

---

# Context

AnyCompany, an e-commerce company:

- Wants to maintain control of proprietary data (IP / Licensing)

- Must reduce __$$$__ and reliance on public API models (e.g., Gemini, Claude, Cohere, etc)

- Has unique GDPR and compliance requirements (i.e., customers in the E.U.)

---

# Our Constraints

--

> Complex ETL pipeline makes data-to-inference non-trivial

> Many different teams experimenting with and building custom models (i.e., no model standardization)

> Leadership wants to leverage in-house infra and enginnering resources

---

### Leverage KubeRay! (Ray on K8s)

- Leverage IaC to provision our own infra on GCP

- Reserve A100s for model inference

- Host and serve our own Gemma models (7-40B)

<img title="survey2" src=assets/kube_ray.png >

--

###

<a href="http://127.0.0.1:8000/steps"> Let's checkout the steps 👇</a>

