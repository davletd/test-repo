resource "google_compute_instance" "tfer--instance-20240605-145222" {
  boot_disk {
    auto_delete = "true"
    device_name = "instance-20240605-145222"
    mode        = "READ_WRITE"
    source      = "https://www.googleapis.com/compute/v1/projects/cloo-1714461127593/zones/us-central1-c/disks/instance-20240605-145222"
  }

  can_ip_forward = "false"

  confidential_instance_config {
    enable_confidential_compute = "false"
  }

  deletion_protection = "false"
  enable_display      = "false"

  labels = {
    goog-ops-agent-policy = "v2-x86-template-1-2-0"
  }

  machine_type = "n2-highcpu-8"

  metadata = {
    enable-osconfig = "TRUE"
    ssh-keys        = "tymon:ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPsy2kVC1V19HnzZwEf9ECeoat9qzSaPssx8ylthKR8f3Or4evpBJL4/HY5G3tWuSKSutrTkOM8IxaPA+BK9h7M= google-ssh {\"userName\":\"tymon@cloo.ai\",\"expireOn\":\"2024-07-19T19:08:13+0000\"}\ntymon:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAFBNgQhtjpICqrk3K6cWiBRHKqXqhg2brua6/zqvnRaS97NB1ukbAXajY8NiVUkTwhoqbHGwQiColOHiT8v0iZuaM6llsYHQDky+cHeitSB7SF29HqUaEdY8nSAts4NmbqGnYnAl+TAANMPCRe3ERDvpPAj4lyEEd1rQ9bqfJQ8KS+BCZTGCcn4B7xlfuBXHG08YIKjKcHwoD5hAhGHK8ed4OFPUCEJn42IN5Urk9hf04k0/ilfbOuYufne/5ZamwlzS8iihQl2hQrslR/Wc8aWOv5wvg2y9QpozsCPaFiVUhJQ80C6aPEF+3AKueseJFtEeHpFmC+dYGKl2QF3ELo8= google-ssh {\"userName\":\"tymon@cloo.ai\",\"expireOn\":\"2024-07-19T19:08:31+0000\"}"
  }

  name = "instance-20240605-145222"

  network_interface {
    access_config {
      nat_ip       = "34.55.251.188"
      network_tier = "PREMIUM"
    }

    network            = "https://www.googleapis.com/compute/v1/projects/cloo-1714461127593/global/networks/default"
    network_ip         = "10.7.0.2"
    queue_count        = "0"
    stack_type         = "IPV4_ONLY"
    subnetwork         = "https://www.googleapis.com/compute/v1/projects/cloo-1714461127593/regions/us-central1/subnetworks/cloud-run-internal"
    subnetwork_project = "cloo-1714461127593"
  }

  project = "cloo-1714461127593"

  reservation_affinity {
    type = "ANY_RESERVATION"
  }

  scheduling {
    automatic_restart   = "true"
    min_node_cpus       = "0"
    on_host_maintenance = "MIGRATE"
    preemptible         = "false"
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "958555716070-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = "true"
    enable_secure_boot          = "false"
    enable_vtpm                 = "true"
  }

  zone = "us-central1-c"
}
