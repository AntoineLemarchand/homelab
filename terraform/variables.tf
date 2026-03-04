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
