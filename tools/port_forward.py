#!/usr/bin/env python
# -*- coding: utf-8 -*-

from typing import List
import os
import sys
import subprocess
import time

PROJECT_ID = os.getenv("PROJECT_ID", "llm-serve-112")
ZONE = os.getenv("ZONE", "us-central1")
CLUSTER_NAME = os.getenv("CLUSTER_NAME", "testing-serving-gcp-us-central1")

RAY_DASHBOARD_SVC_NAME = os.getenv(
    "RAY_DASHBOARD_SVC_NAME", "svc/google-gemma-2b-model-server-head-svc"
)
RAY_DASHBOARD_SVC_PORTS = os.getenv("RAY_DASHBOARD_SVC_PORTS", "8265:8265")
RAY_DASHBOARD_SVC_NAMESPACE = os.getenv("RAY_DASHBOARD_SVC_NAMESPACE", "ray")

RAY_MODEL_SERVER_SVC_NAME = os.getenv(
    "RAY_DASHBOARD_SVC_NAME", "svc/google-gemma-2b-model-server-head-svc"
)
RAY_MODEL_SERVER_SVC_PORTS = os.getenv("RAY_DASHBOARD_SVC_PORTS", "8000:8000")
RAY_MODEL_SERVER_SVC_NAMESPACE = os.getenv("RAY_DASHBOARD_SVC_NAMESPACE", "ray")


PARAMS = dict(
    ray=(
        PROJECT_ID,
        ZONE,
        CLUSTER_NAME,
        RAY_DASHBOARD_SVC_NAMESPACE,
        RAY_DASHBOARD_SVC_NAME,
        RAY_DASHBOARD_SVC_PORTS,
    ),
    model_server=(
        PROJECT_ID,
        ZONE,
        CLUSTER_NAME,
        RAY_MODEL_SERVER_SVC_NAMESPACE,
        RAY_MODEL_SERVER_SVC_NAME,
        RAY_MODEL_SERVER_SVC_PORTS,
    ),
)

SERVICES = ["ray", "model_server"]

if __name__ == "__main__":

    if sys.argv[1:]:

        SERVICES = sys.argv[1:]


def _port_forward(command: List) -> int:
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
    )

    port = command[-1].split(":")[0]

    try:
        with process.stdout:
            for line in iter(process.stdout.readline, b""):
                if f"Forwarding from 127.0.0.1:{port}" in line.decode("utf-8"):
                    return 1
            return 0
    finally:
        process.kill()


def print_hyperlink(uri: str, label: str = None) -> str:
    if label is None:
        label = uri
    parameters = ""

    # OSC 8 ; params ; URI ST <name> OSC 8 ;; ST
    escape_mask = "\033]8;{};{}\033\\{}\033]8;;\033\\"

    return escape_mask.format(parameters, uri, label)


def main():

    if os.getenv("CI", "1"):
        # Weirdness happens if you try to pkill on gihhub actions: it interprets
        # the SIGKILL as though the main program was killed, and exits the
        # the workflow.
        for service in SERVICES:

            _, _, _, _, name, *_ = PARAMS[service]

            processes = subprocess.run(["ps", "aux"], capture_output=True)

            for process in processes.stdout.decode().split("\n"):
                if name in process:
                    pid = int(process.split()[1])
                    os.kill(pid, 9)
                    print(f"Killed existing {service} port-forward process.")

    while SERVICES:
        for service in SERVICES:

            project_id, zone, cluster_name, namespace, name, ports = PARAMS[service]

            command = [
                "kubectl",
                f"--context=gke_{project_id}_{zone}_{cluster_name}",
                f"--namespace={namespace}",
                "port-forward",
                f"{name}",
                f"{ports}",
            ]

            if not _port_forward(command):
                print(
                    f'Could not port forward "{service}", ' "retrying in 5 seconds..."
                )
                time.sleep(5)
            else:
                link = f'http://localhost:{ports.split(":")[0]}'

                msg = f'Port forwarding "{service}" was successful. '
                msg += f"Goto {print_hyperlink(link)} to "
                msg += "view the dashboard. "
                print(msg)

                os.system(" ".join(command) + " > /dev/null 2>&1 &")
                SERVICES.remove(service)

    print("All services are port forwarding correctly...")


if __name__ == "__main__":

    main()
