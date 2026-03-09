locals {
  all_nodes = merge(var.control_planes, var.workers)
}

resource "proxmox_virtual_environment_vm" "talos_nodes" {
  for_each = local.all_nodes

  name = each.key
  description = "Managed by Terraform"
  tags = ["terraform"]
  node_name = each.value.host_node
  on_boot = true
  vm_id = each.value.vm_id

  cpu {
    cores = each.value.cpu
    type = "host"
  }

  memory {
    dedicated = each.value.ram
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = each.value.datastore_id
    file_id = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    file_format = "raw"
    interface = "virtio0"
    size = each.value.disk_size
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "local"
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.default_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }
}

