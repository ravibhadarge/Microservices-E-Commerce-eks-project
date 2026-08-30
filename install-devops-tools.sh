#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log) 2>&1

echo "======================================"
echo "   DEVOPS TOOLS INSTALLATION START"
echo "======================================"

export DEBIAN_FRONTEND=noninteractive

echo "===== SYSTEM UPDATE ====="

apt-get update -y
apt-get upgrade -y

echo "===== BASE PACKAGES ====="

apt-get install -y \
    curl \
    wget \
    git \
    jq \
    vim \
    unzip \
    tar \
    zip \
    python3 \
    python3-pip \
    maven \
    fontconfig \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https

echo "===== JAVA 21 ====="

apt-get install -y openjdk-21-jdk

cat > /etc/profile.d/java21.sh <<'EOF'
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
EOF

chmod +x /etc/profile.d/java21.sh

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

java -version

echo "===== JENKINS ====="

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
    -o /usr/share/keyrings/jenkins-keyring.asc

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
    > /etc/apt/sources.list.d/jenkins.list

apt-get update -y
apt-get install -y jenkins

systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

echo "Jenkins status:"
systemctl --no-pager --full status jenkins || true

echo "===== NODEJS 22 ====="

curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

node --version
npm --version

echo "===== DOCKER ====="

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list

apt-get update -y

apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu
usermod -aG docker jenkins

systemctl restart docker
systemctl restart jenkins

echo "Docker:"
docker --version

echo "Docker Compose:"
docker compose version

echo "===== GITHUB CLI ====="

mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg

chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list

apt-get update -y
apt-get install -y gh

gh --version

echo "===== AWS CLI ====="

curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    -o /tmp/awscliv2.zip

rm -rf /tmp/aws

unzip -q /tmp/awscliv2.zip -d /tmp

/tmp/aws/install --update

rm -rf /tmp/aws /tmp/awscliv2.zip

aws --version

echo "===== KUBECTL ====="

KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

curl -LO \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

rm -f kubectl

kubectl version --client

echo "===== HELM ====="

curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    | bash

helm version

echo "===== TERRAFORM ====="

TF_VERSION="1.13.1"

curl -fsSL \
    -o /tmp/terraform.zip \
    "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"

unzip -o /tmp/terraform.zip -d /tmp/terraform

install -m 0755 /tmp/terraform/terraform /usr/local/bin/terraform

rm -rf /tmp/terraform /tmp/terraform.zip

terraform version

echo "===== EKSCTL ====="

EKSCTL_VERSION=$(curl -sL https://api.github.com/repos/eksctl-io/eksctl/releases/latest | jq -r '.tag_name')

curl --silent --location \
    "https://github.com/eksctl-io/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_${EKSCTL_VERSION#v}_Linux_amd64.tar.gz" \
    -o /tmp/eksctl.tar.gz

tar -xzf /tmp/eksctl.tar.gz -C /tmp

install -m 0755 /tmp/eksctl /usr/local/bin/eksctl

rm -f /tmp/eksctl /tmp/eksctl.tar.gz

eksctl version

echo "===== AWS IAM AUTHENTICATOR ====="

curl -Lo /usr/local/bin/aws-iam-authenticator \
    https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/latest/download/aws-iam-authenticator_linux_amd64

chmod +x /usr/local/bin/aws-iam-authenticator

aws-iam-authenticator version || true

echo "===== JENKINS USER CONFIGURATION ====="

usermod -aG docker jenkins

systemctl restart jenkins

echo "===== TOOL VERSIONS ====="

echo "----- JAVA -----"
java -version

echo "----- GIT -----"
git --version

echo "----- MAVEN -----"
mvn --version

echo "----- NODE -----"
node --version

echo "----- NPM -----"
npm --version

echo "----- DOCKER -----"
docker --version

echo "----- DOCKER COMPOSE -----"
docker compose version

echo "----- AWS CLI -----"
aws --version

echo "----- GH CLI -----"
gh --version

echo "----- KUBECTL -----"
kubectl version --client

echo "----- HELM -----"
helm version

echo "----- TERRAFORM -----"
terraform version

echo "----- EKSCTL -----"
eksctl version

echo "======================================"
echo "   DEVOPS TOOLS INSTALLATION COMPLETE"
echo "======================================"

echo ""
echo "Jenkins URL:"
echo "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"

echo ""
echo "Jenkins Initial Admin Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword

echo ""
echo "IMPORTANT:"
echo "Log out and log back in before using Docker as ubuntu."
