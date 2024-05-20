#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright 2021-2022 Pocket Portfolio - All Rights Reserved
# Unauthorized copying of this file is strictly prohibited.
#
# "Author: Nathan Matare <nathan.matare@pocket-portfolio.com>"
#
# """ Port Forward helper Script
# This should probably be written in GO or be a shell script...
# """

from typing import List
import os
import sys
import subprocess
import time

PROJECT_ID = os.getenv("PROJECT_ID", "llm-serve-423918")
ZONE = os.getenv("ZONE", "us-east1-b")
CLUSTER_NAME = os.getenv("CLUSTER_NAME", "llm-serve")

GRAFANA_SVC_NAME = os.getenv("GRAFANA_SVC_NAME", "svc/prometheus-grafana")
GRAFANA_SVC_PORTS = os.getenv("GRAFANA_SVC_PORTS", "8000:80")
GRAFANA_SVC_NAMESPACE = os.getenv("GRAFANA_SVC_NAMESPACE", "monitoring")

PARAMS = dict(
    grafana=(
        PROJECT_ID,
        ZONE,
        CLUSTER_NAME,
        GRAFANA_SVC_NAMESPACE,
        GRAFANA_SVC_NAME,
        GRAFANA_SVC_PORTS,
    ),
)

SERVICES = ["ray-dashboard", "ingress"]

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
