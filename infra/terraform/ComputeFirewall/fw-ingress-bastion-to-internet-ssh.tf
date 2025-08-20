resource "google_compute_firewall" "fw_ingress_bastion_to_internet_ssh" {
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }

  direction     = "INGRESS"
  name          = "fw-ingress-bastion-to-internet-ssh"
  network       = "https://www.googleapis.com/compute/v1/projects/adlah3/global/networks/honeynet-vpc"
  priority      = 1000
  project       = "adlah3"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]
}
# terraform import google_compute_firewall.fw_ingress_bastion_to_internet_ssh projects/adlah3/global/firewalls/fw-ingress-bastion-to-internet-ssh
