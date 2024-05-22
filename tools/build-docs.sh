#!/bin/bash
# DESCRIPTION: **Public** global fabric-* package installer

set -e
# set -ve

export CONDA_DEFAULT_ENV=llm-serve
export PYTHON_VERSION=3.10
export PYTHON_PIP_VERSION=23.2.1
export TERM=${TERM:-"xterm-256color"}
export PYTHONUNBUFFERED=1

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

echo "${green}Creating a new ($CONDA_DEFAULT_ENV) conda (py-$PYTHON_VERSION) environment...${reset}"
conda create --yes --name "$CONDA_DEFAULT_ENV" \
  pip="$PYTHON_PIP_VERSION" python="$PYTHON_VERSION" -c conda-forge >>/dev/null

# Save the conda env because the below two commands will
# refert back to the base env
conda_env=${CONDA_DEFAULT_ENV}

source "$(conda info --base)/etc/profile.d/conda.sh"
eval "$(conda shell.bash hook)"

conda activate "${conda_env}"
export CONDA_DEFAULT_ENV="$conda_env"

pip install \
  mkdocs \
  mkdocs-material==7.1.0 \
  nbconvert==6.0.7 \
  mkdocs-jupyter==0.16.1 \
  mkdocstrings==0.15.0 \
  mkdocs-git-revision-date-localized-plugin==0.7.1 \
  mkdocs-plugin-progress==1.2.0

# EOF