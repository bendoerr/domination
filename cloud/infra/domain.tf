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

resource "digitalocean_record" "dmarc" {
  domain = "cloud.bendoerr.com"
  type   = "TXT"
  name   = "_dmarc"
  value  = "v=DMARC1; p=none; rua=mailto:craftsman@bendoerr.me; rf=afrf; pct=100; ri=1800"
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
}

resource "digitalocean_record" "gateway_internal" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "gateway.internal"
  value  = "${digitalocean_droplet.gateway.ipv4_address_private}"
}

resource "digitalocean_record" "gateway_dkim" {
  domain = "cloud.bendoerr.com"
  type   = "TXT"
  name   = "gateway._domainkey"
  value  = "v=DKIM1; k=rsa; g=*; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCtaB00DRKNNVXlAXGK7COCQYducPKap6pUxRoiT3NJWRMktXP/FCtza450yer6TuyLXOF9Xo92RkcSLJOfwboFVyRs4F0yy4ez0CpGW3GLkXnjUZP8Y2giifwQG57kWIWUKC2Nk3n+l7czOxPeD1RXHN5C5RdeKQpFKopl0iLoEwIDAQAB"
}

resource "digitalocean_record" "gateway_spf" {
  domain = "cloud.bendoerr.com"
  type   = "TXT"
  name   = "gateway"
  value  = "v=spf1 a a:gateway.cloud.bendoerr.com include:_spf.google.com ~all"
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
}

resource "digitalocean_record" "minecraft_internal" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "minecraft.internal"
  value  = "${digitalocean_droplet.minecraft.ipv4_address_private}"
}

resource "digitalocean_record" "minecraft_spf" {
  domain = "cloud.bendoerr.com"
  type   = "TXT"
  name   = "minecraft"
  value  = "v=spf1 a a:gateway.cloud.bendoerr.com include:_spf.google.comm ~all"
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
}

resource "digitalocean_record" "minecraft-pe_internal" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "minecraft-pe.internal"
  value  = "${digitalocean_droplet.minecraft-pe.ipv4_address_private}"
}

resource "digitalocean_record" "minecraft-pe_spf" {
  domain = "cloud.bendoerr.com"
  type   = "TXT"
  name   = "minecraft-pe"
  value  = "v=spf1 a a:gateway.cloud.bendoerr.com include:_spf.google.comm ~all"
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
}

resource "digitalocean_record" "discourse_internal" {
  domain = "cloud.bendoerr.com"
  type   = "A"
  name   = "discourse.internal"
  value  = "${digitalocean_droplet.discourse.ipv4_address_private}"
}

resource "digitalocean_record" "discourse_spf" {
  domain = "cloud.bendoerr.com"
  type   = "TXT"
  name   = "discourse"
  value  = "v=spf1 a a:gateway.cloud.bendoerr.com include:_spf.google.comm ~all"
}

################################################################################
#
# shadowcville.com
#

resource "digitalocean_domain" "shadowcville_com" {
  name       = "shadowcville.com"
  ip_address = "${digitalocean_droplet.discourse.ipv4_address}"
}

resource "digitalocean_record" "shadowcville_com_spf" {
  domain = "shadowcville.com"
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 a a:gateway.cloud.bendoerr.com include:_spf.google.comm ~all"
}
