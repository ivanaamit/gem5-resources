packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "image_name" {
  type    = string
  default = "arm-ubuntu"
}

variable "ssh_password" {
  type    = string
  default = "12345"
}

variable "ssh_username" {
  type    = string
  default = "gem5"
}

source "qemu" "initialize" {
  boot_command     = [
                      "c<wait>",
                      "linux /casper/vmlinuz autoinstall ds=nocloud-net\\;s=http://{{.HTTPIP}}:{{.HTTPPort}}/ --- ",
                      "<enter><wait>",
                      "initrd /casper/initrd",
                      "<enter><wait>",
                      "boot",
                      "<enter>",
                      "<wait>"
                      ]
  cpus             = "4"
  disk_size        = "4600"
  format           = "raw"
  headless         = "true"
  http_directory   = "http-24-04"
  iso_checksum     = "sha256:d2d9986ada3864666e36a57634dfc97d17ad921fa44c56eeaca801e7dab08ad7"
  iso_urls         = ["https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04-live-server-arm64.iso"]
  memory           = "8192"
  output_directory = "disk-image-24-04"
  qemu_binary      = "/usr/bin/qemu-system-aarch64"
  qemuargs         = [  ["-boot", "order=dc"],
                        ["-bios", "./files/flash0.img"],
                        ["-cpu", "host"],
                        ["-enable-kvm"],
                        ["-machine", "virt"],
                        ["-machine", "gic-version=3"],
                        ["-vga", "virtio"],
                        ["-device","virtio-gpu-pci"],
                        ["-device", "qemu-xhci"],
                        ["-device","usb-kbd"],

                      ]
  shutdown_command = "echo '${var.ssh_password}'|sudo -S shutdown -P now"
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_wait_timeout = "60m"
  vm_name          = "${var.image_name}"
  ssh_handshake_attempts = "1000"
}

build {
  sources = ["source.qemu.initialize"]

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/exit.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/gem5_init.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/after_boot.sh"
  }

  provisioner "file" {
    destination = "/home/gem5/"
    source      = "files/serial-getty@.service"
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -E -S bash '{{ .Path }}'"
    scripts         = ["scripts/post-installation.sh"]
    expect_disconnect = true
  }

}
