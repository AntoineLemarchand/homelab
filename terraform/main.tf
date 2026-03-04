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

  }
}

provider "proxmox" {
  endpoint = "https://proxmox.netbird.cloud:8006/"
  insecure = true
}
