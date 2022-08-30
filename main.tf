terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}

variable "kvm01" {
  type = map(object({
    cpu         = number
    ram       = number
    disk_size    = number
    mgmt_ip = string
    network_interfaces = list(string)
    block_devices = list(string)
  }))
  default = {}
}

variable "kvm02" {
  type = map(object({
    cpu         = number
    ram       = number
    disk_size    = number
    mgmt_ip = string
    network_interfaces = list(string)
    block_devices = list(string)
  }))
  default = {}
}

variable "kvm03" {
  type = map(object({
    cpu         = number
    ram       = number
    disk_size    = number
    mgmt_ip = string
    network_interfaces = list(string)
    block_devices = list(string)
  }))
  default = {}
}

module "kvm01" {
	source = "./modules"
	uri = "qemu+ssh://ubuntu@10.42.168.11/system"
	vms = var.kvm01
}

module "kvm02" {
  source = "./modules"
  uri = "qemu+ssh://ubuntu@10.42.168.12/system"
  vms = var.kvm02
}

module "kvm03" {
  source = "./modules"
  uri = "qemu+ssh://ubuntu@10.42.168.13/system"
  vms = var.kvm03
}



