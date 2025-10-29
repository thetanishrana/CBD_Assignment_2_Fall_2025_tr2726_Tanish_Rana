#!/bin/bash

echo "=== Installing Prerequisites for Cloud Computing Assignment 2 ==="
echo ""

# Install Docker Desktop
echo "1. Installing Docker Desktop..."
if ! command -v docker &> /dev/null; then
    brew install --cask docker
    echo "✓ Docker Desktop installed. Please start it from Applications folder."
    echo "  Wait for the whale icon to appear in your menu bar."
else
    echo "✓ Docker already installed"
fi

# Install kubectl
echo ""
echo "2. Installing kubectl (Kubernetes CLI)..."
if ! command -v kubectl &> /dev/null; then
    brew install kubectl
    echo "✓ kubectl installed"
else
    echo "✓ kubectl already installed"
fi

# Install Minikube
echo ""
echo "3. Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    brew install minikube
    echo "✓ Minikube installed"
else
    echo "✓ Minikube already installed"
fi

# Install AWS CLI
echo ""
echo "4. Installing AWS CLI..."
if ! command -v aws &> /dev/null; then
    brew install awscli
    echo "✓ AWS CLI installed"
else
    echo "✓ AWS CLI already installed"
fi

# Install eksctl (for easier EKS cluster management)
echo ""
echo "5. Installing eksctl (EKS management tool)..."
if ! command -v eksctl &> /dev/null; then
    brew tap weaveworks/tap
    brew install weaveworks/tap/eksctl
    echo "✓ eksctl installed"
else
    echo "✓ eksctl already installed"
fi

# Install Helm (for Prometheus installation)
echo ""
echo "6. Installing Helm (Kubernetes package manager)..."
if ! command -v helm &> /dev/null; then
    brew install helm
    echo "✓ Helm installed"
else
    echo "✓ Helm already installed"
fi

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "Next steps:"
echo "1. Start Docker Desktop from Applications folder"
echo "2. Wait for Docker to fully start (whale icon in menu bar)"
echo "3. Verify installation by running: docker --version"
echo ""
echo "For AWS EKS, you'll also need to:"
echo "1. Configure AWS credentials: aws configure"
echo "2. Enter your AWS Access Key, Secret Key, and region"
