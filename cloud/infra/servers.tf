################################################################################
#
# Terraform Template containing Droplet Resources
#
################################################################################

################################################################################
#
# gateway.cloud.bendoerr.com
#

resource "digitalocean_droplet" "gateway" {
  # image = "ubuntu-16-04-x64"
  image  = ""
  name   = "gateway"
  region = "nyc3"
  size   = "512mb"

  backups            = "false"
  ipv6               = "false"
  private_networking = true

  ssh_keys = []

  resize_disk = "false"

  tags = [
    "${digitalocean_tag.mail-relays.id}",
    "${digitalocean_tag.vpn-gateways.id}",
    "${digitalocean_tag.all-servers.id}",
  ]

  connection {
    user     = "root"
    type     = "ssh"
    key_file = "${var.digitalocean_ssh_key}"
    timeout  = "2m"
  }
}

################################################################################
#
# minecraft.cloud.bendoerr.com
#

resource "digitalocean_droplet" "minecraft" {
  # image = "ubuntu-16-04-x64"
  image  = ""
  name   = "minecraft"
  region = "nyc3"
  size   = "2gb"

  backups            = "false"
  ipv6               = "false"
  private_networking = true

  ssh_keys = []

  resize_disk = "false"

  tags = [
    "${digitalocean_tag.minecraft-server.id}",
    "${digitalocean_tag.all-servers.id}",
  ]

  connection {
    user     = "root"
    type     = "ssh"
    key_file = "${var.digitalocean_ssh_key}"
    timeout  = "2m"
  }
}

################################################################################
#
# minecraft-pe.cloud.bendoerr.com
#

resource "digitalocean_droplet" "minecraft-pe" {
  # image = "ubuntu-16-04-x64"
  image  = ""
  name   = "minecraft-pe"
  region = "nyc3"
  size   = "512mb"

  backups            = "false"
  ipv6               = "false"
  private_networking = true

  ssh_keys = []

  resize_disk = "false"

  tags = [
    "${digitalocean_tag.minecraft-pe-server.id}",
    "${digitalocean_tag.all-servers.id}",
  ]

  connection {
    user     = "root"
    type     = "ssh"
    key_file = "${var.digitalocean_ssh_key}"
    timeout  = "2m"
  }
}

################################################################################
#
# discourse.cloud.bendoerr.com
#

resource "digitalocean_droplet" "discourse" {
  image  = "ubuntu-16-04-x64"
  name   = "discourse"
  region = "nyc3"
  size   = "2gb"

  backups            = "false"
  ipv6               = "false"
  private_networking = true

  ssh_keys = [
    "${var.digitalocean_ssh_fingerprint}",
  ]

  resize_disk = "false"

  tags = [
    "${digitalocean_tag.docker-host.id}",
    "${digitalocean_tag.discourse-server.id}",
    "${digitalocean_tag.all-servers.id}",
  ]

  connection {
    user     = "root"
    type     = "ssh"
    key_file = "${var.digitalocean_ssh_key}"
    timeout  = "2m"
  }
}
