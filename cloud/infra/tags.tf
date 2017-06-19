################################################################################
#
# Terraform Template containing Tag Resources
#
################################################################################

resource "digitalocean_tag" "all-servers" {
  name = "all-servers"
}

resource "digitalocean_tag" "mail-relays" {
  name = "mail-relays"
}

resource "digitalocean_tag" "vpn-gateways" {
  name = "vpn-gateways"
}

resource "digitalocean_tag" "minecraft-server" {
  name = "minecraft-server"
}

resource "digitalocean_tag" "minecraft-pe-server" {
  name = "minecraft-pe-server"
}

resource "digitalocean_tag" "testing-servers" {
  name = "testing-servers"
}

resource "digitalocean_tag" "docker-host" {
  name = "docker-host"
}

resource "digitalocean_tag" "discourse-server" {
  name = "discourse-server"
}
