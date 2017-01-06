variable "digitalocean_ssh_key" {
    type = "string"
    description = "SSH Private Key File"
    default = "/Users/bdoerr/.ssh/id_ed25519"
}

variable "digitalocean_ssh_pub" {
    type = "string"
    description = "SSH Public Key File"
    default = "/Users/bdoerr/.ssh/id_ed25519.pub"
}

variable "digitalocean_ssh_fingerprint" {
    type = "string"
    description = "SSH Fingerprint"
    default = "6f:2b:25:4e:e9:9a:4b:bc:d6:6c:4f:de:a6:be:68:77"
}

provider "digitalocean" {}

resource "digitalocean_ssh_key" "ed25519-bdoerr" {
    name = "ed25519-bdoerr@m45754bdoerr.premierinc.com"
    public_key = "${file("${var.digitalocean_ssh_pub}")}"
}
