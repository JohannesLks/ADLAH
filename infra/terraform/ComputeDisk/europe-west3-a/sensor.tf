resource "google_compute_disk" "sensor" {
  guest_os_features {
    type = "GVNIC"
  }

  guest_os_features {
    type = "IDPF"
  }

  guest_os_features {
    type = "SEV_CAPABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE"
  }

  guest_os_features {
    type = "SEV_LIVE_MIGRATABLE_V2"
  }

  guest_os_features {
    type = "SEV_SNP_CAPABLE"
  }

  guest_os_features {
    type = "TDX_CAPABLE"
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }

  guest_os_features {
    type = "VIRTIO_SCSI_MULTIQUEUE"
  }

  image = "https://www.googleapis.com/compute/beta/projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2204-jammy-v20250723"

  labels = {
    managed-by-cnrm = "true"
  }

  licenses                  = ["https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/licenses/ubuntu-minimal-2204-lts"]
  name                      = "sensor"
  physical_block_size_bytes = 4096
  project                   = "adlah3"
  resource_policies         = ["https://www.googleapis.com/compute/v1/projects/adlah3/regions/europe-west3/resourcePolicies/default-schedule-1"]
  size                      = 50
  type                      = "pd-balanced"
  zone                      = "europe-west3-a"
}
# terraform import google_compute_disk.sensor projects/adlah3/zones/europe-west3-a/disks/sensor
