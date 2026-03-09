variable "cluster_name" {
  description = "Name of the cluster"
  type = string
  default = "homelab"
}

variable "proxmox_id" {
  type = object({login = string, password = string})
  sensitive = true
}

variable "talos_version" {
  description = "Version of Talos linux"
  type = string
  default = "v1.12.0"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes"
  type = string
  default = "1.35.2"
}

variable "control_planes" {
  description = "Control plane node definitions"
  type = map(object({
    host_node    = string
    vm_id        = number
    ip           = string
    cpu          = number
    ram          = number
    disk_size    = number
    datastore_id = string
  }))
}

variable "workers" {
  description = "Worker node definitions"
  type = map(object({
    host_node    = string
    vm_id        = number
    ip           = string
    cpu          = number
    ram          = number
    disk_size    = number
    datastore_id = string
  }))
}

variable "cluster_endpoint" {
  description = "Virtual IP for the cluster endpoint"
  type = string
}

variable "default_gateway" {
  description = "The default gateway"
  type = string
  default = "192.168.1.1"
}

variable "netbird_setup_key" {
  description = "The netbird setup key"
  type = string
}
