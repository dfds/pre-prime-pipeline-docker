# ========================================
# CREATE UPDATED BASE IMAGE
# ========================================

FROM debian:stretch-slim AS base

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# ========================================
# GENERAL PREREQUISITES
# ========================================

FROM base

# Explicitly set USER env variable to accomodate issues with golang code being cross-compiled
ENV USER root

RUN apt-get update \
    && apt-get install -y curl unzip git bash-completion jq ssh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Adding  GitHub public SSH key to known hosts
RUN ssh -T -o "StrictHostKeyChecking no" -o "PubkeyAuthentication no" git@github.com || true


# ========================================
# PYTHON
# ========================================

RUN apt-get update \
    && apt-get install -y python python-pip python3 python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# ========================================
# AWS CLI
# ========================================

# 1.16.117 requires botocore 1.12.86
# Not sure how to handle this, pipfile and pipfile.lock best
# See also https://github.com/aws/aws-cli/issues/3892

ENV AWSCLI_VERSION=1.16.95

RUN python3 -m pip install --upgrade pip \
    && pip3 install pipenv awscli==${AWSCLI_VERSION} \
    && echo "complete -C '$(which aws_completer)' aws" >> ~/.bashrc

# ========================================
# TERRAFORM
# ========================================

ENV TERRAFORM_VERSION=0.11.10

RUN curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip \
    && rm terraform.zip \
    && mv terraform /usr/local/bin/
    #&& terraform -install-autocomplete


# ========================================
# TERRAGRUNT
# ========================================

ENV TERRAGRUNT_VERSION=0.16.14

RUN curl -L https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 -o terragrunt \
    && chmod +x terragrunt \
    && mv terragrunt /usr/local/bin/


# ========================================
# KUBECTL
# ========================================

ENV KUBECTL_VERSION=1.12.0

RUN curl -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o kubectl \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/


CMD [ "bash" ]

# ========================================
# ISSUES
# ========================================

# debconf: unable to initialize frontend: Dialog
# debconf: (TERM is not set, so the dialog frontend is not usable.)
# debconf: falling back to frontend: Readline
# debconf: unable to initialize frontend: Readline
# debconf: (Can't locate Term/ReadLine.pm in @INC (you may need to install the Term::ReadLine module) (@INC contains: /etc/perl /usr/local/lib/x86_64-linux-gnu/perl/5.24.1 /usr/local/share/perl/5.24.1 /usr/lib/x86_64-linux-gnu/perl5/5.24 /usr/share/perl5 /usr/lib/x86_64-linux-gnu/perl/5.24 /usr/share/perl/5.24 /usr/local/lib/site_perl /usr/lib/x86_64-linux-gnu/perl-base .) at /usr/share/perl5/Debconf/FrontEnd/Readline.pm line 7, <> line 3.)
# debconf: falling back to frontend: Teletype
# dpkg-preconfigure: unable to re-open stdin:
