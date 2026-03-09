locals {
  common_patches = [
    yamlencode({
      apiVersion  = "v1alpha1"
      kind        = "ExtensionServiceConfig"
      name        = "netbird"
      environment = [
        "NB_SETUP_KEY=${var.netbird_setup_key}",
      ]
    }),
  ]
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "controlplane" {
  for_each = var.control_planes

  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.cluster_endpoint}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  kubernetes_version = var.kubernetes_version

  config_patches = concat(local.common_patches, [
    yamlencode({
      cluster = {
        allowSchedulingOnControlPlanes = true
      }
    }),
  ])
}

data "talos_machine_configuration" "worker" {
  for_each = var.workers

  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.cluster_endpoint}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
  kubernetes_version = var.kubernetes_version

  config_patches = concat(local.common_patches, [
    yamlencode({
      machine = {
        kernel = {
          modules = [
            { name = "nbd" },
            { name = "iscsi-tcp" },
            { name = "iscsi-generic" },
            { name = "configfs" },
          ]
        }
      }
    })
  ])
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for node in local.all_nodes : node.ip]
  endpoints            = [for cp in var.control_planes : cp.ip]
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = var.control_planes
  depends_on = [proxmox_virtual_environment_vm.talos_nodes]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane[each.key].machine_configuration
  node                        = each.value.ip

}

resource "talos_machine_configuration_apply" "worker" {
  for_each = var.workers
  depends_on = [proxmox_virtual_environment_vm.talos_nodes]


  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[each.key].machine_configuration
  node                        = each.value.ip
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [ talos_machine_configuration_apply.controlplane ]

  node = values(var.control_planes)[0].ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = values(var.control_planes)[0].ip
}

output "talosconfig" {
  value = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

resource "local_file" "kubeconfig" {
  depends_on = [talos_cluster_kubeconfig.this]
  filename   = "kubeconfig"
  content    = talos_cluster_kubeconfig.this.kubeconfig_raw
}

