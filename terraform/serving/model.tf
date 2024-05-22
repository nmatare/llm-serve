resource "kubernetes_config_map" "model_src" {
  depends_on = [helm_release.kuberay-operator]

  metadata {
    name      = local.model_qualified_name
    namespace = kubernetes_namespace.ray.metadata[0].name
  }

  data = {
    "${var.settings.model_import_file}.py" = <<EOD
import ray
import os
import transformers
import torch
from ray import serve
from fastapi import FastAPI, Body
from transformers import AutoTokenizer, AutoModelForCausalLM, AutoConfig
from pydantic import BaseModel

class Query(BaseModel):
    text: str

app = FastAPI()

@serve.deployment(
    num_replicas=int(os.environ['RAY_SERVE_NUM_REPLICAS']),
    ray_actor_options={"num_cpus": 8, "num_gpus": 1}
)
@serve.ingress(app)
class App:
    tokenizer = ""
    pipeline = ""

    def __init__(self):
        self.tokenizer = AutoTokenizer.from_pretrained(
            "${var.settings.model_name}",
            token=os.environ["HUGGINGFACE_API_SECRET"]
        )

        model = AutoModelForCausalLM.from_pretrained(
            "${var.settings.model_name}",
            device_map="auto",
            token=os.environ["HUGGINGFACE_API_SECRET"]
        )

        self.pipeline = transformers.pipeline(
            "text-generation",
            model=model,
            torch_dtype=torch.float16,
            device_map="auto",
            tokenizer=self.tokenizer,
            token=os.environ["HUGGINGFACE_API_SECRET"]
        )

    @app.post("/")
    async def chat(self, payload: dict = Body(...)) -> str:
        print("query text: " + payload['text'])

        sequences = self.pipeline(
            payload['text'],
            do_sample=True,
            top_k=10,
            num_return_sequences=1,
            eos_token_id=self.tokenizer.eos_token_id,
            max_length=200
        )

        val = ""
        for seq in sequences:
            val = seq['generated_text']
            print("val: " + val)

        return val

entrypoint = App.bind()
EOD
  }
}
