resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

locals {
  node_ips = values(var.nodes)
}

resource "proxmox_virtual_environment_vm" "talos_nodes" {
  for_each = var.nodes

  name = each.key
  description = "Managed by Terraform"
  tags = ["terraform"]
  node_name = var.cluster_name
  on_boot = true

  cpu {
    cores = 4
    type = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local"
    file_id = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    file_format = "raw"
    interface = "virtio0"
    size = 20
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "local"
    ip_config {
      ipv4 {
        address = "${each.value}/24"
        gateway = var.default_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }
}

data "talos_client_configuration" "talosconfig" {
  cluster_name = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = local.node_ips
}

data "talos_machine_configuration" "talosconfig" {
  for_each = var.nodes

  cluster_name = var.cluster_name
  cluster_endpoint = "https://${each.value}:6443"
  machine_type = "controlplane"
  machine_secrets = talos_machine_secrets.this.machine_secrets
  kubernetes_version = var.kubernetes_version

  config_patches = [
    yamlencode({
      cluster = {
        allowSchedulingOnControlPlanes = true
      }
    }),
    # yamlencode({
    # apiVersion  = "v1alpha1"
    # kind        = "ExtensionServiceConfig"
    # name        = "netbird"
    # environment = [
    # "NB_SETUP_KEY=${var.netbird_setup_key}",
    # "NETBIRD_VERSION=0.64.6"
    # ]
    # })
  ]
}

resource "talos_machine_configuration_apply" "nodes" {
  for_each = var.nodes

  depends_on = [ proxmox_virtual_environment_vm.talos_nodes ]
  client_configuration = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.talosconfig[each.key].machine_configuration
  node = each.value
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [ talos_machine_configuration_apply.nodes ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node = local.node_ips[0]
}

data "talos_cluster_health" "health" {
  depends_on = [ talos_machine_configuration_apply.nodes ]
  client_configuration = data.talos_client_configuration.talosconfig.client_configuration
  control_plane_nodes = local.node_ips
  endpoints = data.talos_client_configuration.talosconfig.endpoints
  skip_kubernetes_checks = true
  timeouts = {
    read = "5m"
  }
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [ talos_machine_bootstrap.bootstrap, data.talos_cluster_health.health ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node = local.node_ips[0]
}

output "talosconfig" {
  value = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}
