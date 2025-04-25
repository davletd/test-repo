
terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.0.2"
    }
  }
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  server         = var.vsphere_server
  
  # If you use self-signed certificates
  allow_unverified_ssl = true
}

resource "vsphere_virtual_machine" "vm" {
  name             = "cloudgeni-eu-vm"
  resource_pool_id = var.vsphere_resource_pool_id
  datastore_id     = var.vsphere_datastore_id
  
  # Configure networking
  network_interface {
    network_id   = var.vsphere_network_id
    adapter_type = "vmxnet3"
  }
  
  # Configure the disk and operating system
  disk {
    label            = "disk0"
    size             = 40
    eagerly_scrub    = false
    thin_provisioned = true
  }
  
  guest_id     = "ubuntu-64"
  memory       = 2048
  num_cpus     = 2
  
  lifecycle {
    prevent_destroy = true
  }
}

# Outputs
output "vm_id" {
  value = vsphere_virtual_machine.vm.id
}
