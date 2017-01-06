resource "digitalocean_domain" "cloud_bendoerr_com" {
    name = "cloud.bendoerr.com"
    ip_address = ""
}

resource "digitalocean_record" "dmarc" {
    domain = "cloud.bendoerr.com"
    type = "TXT"
    name = "_dmarc"
    value = "v=DMARC1; p=none; rua=mailto:craftsman@bendoerr.me; rf=afrf; pct=100; ri=1800"
}

resource "digitalocean_record" "spf" {
    domain = "cloud.bendoerr.com"
    type = "TXT"
    name = "@"
    value = "v=spf1 a:cloud.bendoerr.com ip4:${digitalocean_droplet.gateway.ipv4_address} ~all"
}
