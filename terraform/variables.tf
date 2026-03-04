variable "cluster_name" {
  description = "Name of the cluster"
  type = string
  default = "homelab"
}

variable "talos_version" {
  description = "Version of Talos linux"
  type = string
  default = "v1.12.4"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes"
  type = string
  default = "1.35.2"
}

variable "nodes" {
  description = "Name and ips of the cluster nodes"
  type = map(string)
  default = {
    poutou = "192.168.1.50",
    besancenot = "192.168.1.51"
  }
}

variable "cluster_vip" {
  description = "Virtual IP for the cluster endpoint"
  type = string
  default = "192.168.1.40"
}

variable "default_gateway" {
  description = "The default gateway"
  type = string
  default = "192.168.1.1"
}

# variable "netbird_setup_key" {
# description = "The netbird setup key"
# type = string
# }
