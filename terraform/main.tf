terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.97.1"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.11.0-beta.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "3.0.1"
    }
  }
}

provider "kubernetes" {
  config_path = "${local_file.kubeconfig.filename}"
  config_context = var.k8s_context
}

provider "proxmox" {
  endpoint = "https://proxmox.netbird.cloud:8006/"
  insecure = true
}
