terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}


variable "uri" {
  type = string
}

variable "vms" {
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


provider "libvirt" {
  uri = var.uri
}

resource "libvirt_pool" "ubuntu" {
  name = "ubuntu"
  type = "dir"
  path = "/var/lib/libvirt/images/cloud-pool"
}

resource "libvirt_volume" "ubuntu-base" {
  name   = "ubuntu-qcow2"
  pool   = libvirt_pool.ubuntu.name
  source = "https://repo.itera.io/repository/images/ubuntu-focal-20.04.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "ubuntu-volume" {
  for_each          = var.vms
  name   = "${each.key}-volume"
  base_volume_id = libvirt_volume.ubuntu-base.id
  size = each.value["disk_size"] * 1024 * 1024 * 1024
  pool   = libvirt_pool.ubuntu.name
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

data "template_file" "network_config" {
  for_each = var.vms
  template = file("${path.module}/network_config.cfg")
  vars = {
    mgmt_ip = each.value["mgmt_ip"]
  }
}

resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = var.vms
  name           = each.key
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config[each.key].rendered
  pool           = libvirt_pool.ubuntu.name
}

# Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  for_each = var.vms
  name   = each.key
  memory = each.value["ram"] * 1024
  vcpu   = each.value["cpu"]

  cloudinit = libvirt_cloudinit_disk.commoninit[each.key].id
  autostart = true

  network_interface {
    bridge = "br0"
  }

  dynamic "network_interface" {
    for_each = each.value["network_interfaces" ]
    content {
      bridge = network_interface.value
    }
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-volume[each.key].id
  }

  dynamic "disk" {
    for_each = each.value["block_devices"]
    content {
      block_device = disk.value
    }
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
