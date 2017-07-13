################################################################################
#
# Terraform Template containing Domain and Record Resources
#
################################################################################

################################################################################
#
# cloud.bendoerr.com
#

resource "digitalocean_domain" "cloud_bendoerr_com" {
  name       = "cloud.bendoerr.com"
  ip_address = ""
}

resource "digitalocean_record" "cloud_bendoerr_com" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "@"
  value  = "${digitalocean_droplet.gateway.ipv4_address}"
  ttl    = 600
}

resource "digitalocean_record" "dmarc" {
  domain = "cloud.bendoerr.com"
  type   = "TXT"
  name   = "_dmarc"
  value  = "v=DMARC1; p=none; rua=mailto:craftsman@bendoerr.me; rf=afrf; pct=100; ri=1800"
  ttl    = 600
}

resource "digitalocean_record" "dkim" {
  domain = "cloud.bendoerr.com"
  type   = "TXT"
  name   = "gateway._domainkey"
  value  = "v=DKIM1; k=rsa; s=email; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCXwO+lgk2d3JlVcqRx3K5gsns5g5h2EBOTJztJwZICFM5kQSNv5tBZGduZRzkx74sdHZ3Jh59i9f1aZamMNg8VUiN/9V+eRMpvpFIiu403laNJ+1FQMNpS3+wdWheOvfWSH2dvxFRqtMaWUqnCwwQhg5EIjQQ6rNZjKz+I1Eaj9wIDAQAB"
  ttl    = 600
}

resource "digitalocean_record" "spf" {
  domain = "cloud.bendoerr.com"
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 a:cloud.bendoerr.com ~all"
  ttl    = 600
}

################################################################################
#
# gateway.cloud.bendoerr.com
#

resource "digitalocean_record" "gateway" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "gateway"
  value  = "${digitalocean_droplet.gateway.ipv4_address}"
  ttl    = 600
}

resource "digitalocean_record" "gateway_internal" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "gateway.internal"
  value  = "${digitalocean_droplet.gateway.ipv4_address_private}"
  ttl    = 600
}

################################################################################
#
# minecraft.cloud.bendoerr.com
#

resource "digitalocean_record" "minecraft" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "minecraft"
  value  = "${digitalocean_droplet.minecraft.ipv4_address}"
  ttl    = 600
}

resource "digitalocean_record" "minecraft_internal" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "minecraft.internal"
  value  = "${digitalocean_droplet.minecraft.ipv4_address_private}"
  ttl    = 600
}

################################################################################
#
# minecraft-pe.cloud.bendoerr.com
#

resource "digitalocean_record" "minecraft-pe" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "minecraft-pe"
  value  = "${digitalocean_droplet.minecraft-pe.ipv4_address}"
  ttl    = 600
}

resource "digitalocean_record" "minecraft-pe_internal" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "minecraft-pe.internal"
  value  = "${digitalocean_droplet.minecraft-pe.ipv4_address_private}"
  ttl    = 600
}

################################################################################
#
# discourse.cloud.bendoerr.com
#

resource "digitalocean_record" "discourse" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "discourse"
  value  = "${digitalocean_droplet.discourse.ipv4_address}"
  ttl    = 600
}

resource "digitalocean_record" "discourse_internal" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "discourse.internal"
  value  = "${digitalocean_droplet.discourse.ipv4_address_private}"
  ttl    = 600
}

################################################################################
#
# shadowcville.com
#

resource "digitalocean_domain" "shadowcville_com" {
  name       = "shadowcville.com"
  ip_address = "${digitalocean_droplet.discourse.ipv4_address}"
}
