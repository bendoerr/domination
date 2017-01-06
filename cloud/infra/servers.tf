################################################################################
#
# Tags
#

resource "digitalocean_tag" "servers" {
    name = "servers"
}

resource "digitalocean_tag" "mail-relays" {
    name = "mail-relays"
}

resource "digitalocean_tag" "vpn-gateways" {
    name = "vpn-gateways"
}

resource "digitalocean_tag" "minecraft-servers" {
    name = "minecraft-servers"
}

resource "digitalocean_tag" "minecraft-pe-servers" {
    name = "minecraft-pe-servers"
}

resource "digitalocean_tag" "testing-servers" {
    name = "testing-servers"
}

################################################################################
#
# gateway.cloud.bendoerr.com
#

resource "digitalocean_droplet" "gateway" {

    # image = "ubuntu-16-04-x64"
    image = ""
    name = "gateway"
    region = "nyc3"
    size = "512mb"

    backups = "false"
    ipv6 = "false"
    private_networking = true

    ssh_keys = []

    resize_disk = "false"

    tags = [ "${digitalocean_tag.servers.id}"
           , "${digitalocean_tag.mail-relays.id}"
           , "${digitalocean_tag.vpn-gateways.id}"
           ]

    connection {
        user = "root"
        type = "ssh"
        key_file = "${var.digitalocean_ssh_key}"
        timeout = "2m"
    }

}

resource "digitalocean_record" "gateway" {
    domain = "cloud.bendoerr.com"
    type = "A"
    name = "gateway"
    value = "${digitalocean_droplet.gateway.ipv4_address}"
}

resource "digitalocean_record" "gateway_internal" {
    domain = "cloud.bendoerr.com"
    type = "A"
    name = "gateway.internal"
    value = "${digitalocean_droplet.gateway.ipv4_address_private}"
}


resource "digitalocean_record" "gateway_dkim" {
    domain = "cloud.bendoerr.com"
    type = "TXT"
    name = "gateway._domainkey"
    value = "v=DKIM1; k=rsa; g=*; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCtaB00DRKNNVXlAXGK7COCQYducPKap6pUxRoiT3NJWRMktXP/FCtza450yer6TuyLXOF9Xo92RkcSLJOfwboFVyRs4F0yy4ez0CpGW3GLkXnjUZP8Y2giifwQG57kWIWUKC2Nk3n+l7czOxPeD1RXHN5C5RdeKQpFKopl0iLoEwIDAQAB"
}


################################################################################
#
# minecraft.cloud.bendoerr.com
#

resource "digitalocean_droplet" "minecraft" {

    # image = "ubuntu-16-04-x64"
    image = ""
    name = "minecraft"
    region = "nyc3"
    size = "2gb"

    backups = "false"
    ipv6 = "false"
    private_networking = true

    ssh_keys = []

    resize_disk = "false"

    tags = [ "${digitalocean_tag.servers.id}"
           , "${digitalocean_tag.minecraft-servers.id}"
           ]

    connection {
        user = "root"
        type = "ssh"
        key_file = "${var.digitalocean_ssh_key}"
        timeout = "2m"
    }

}

resource "digitalocean_record" "minecraft" {
    domain = "cloud.bendoerr.com"
    type = "A"
    name = "minecraft"
    value = "${digitalocean_droplet.minecraft.ipv4_address}"
}

resource "digitalocean_record" "minecraft_internal" {
    domain = "cloud.bendoerr.com"
    type = "A"
    name = "minecraft.internal"
    value = "${digitalocean_droplet.minecraft.ipv4_address_private}"
}

################################################################################
#
# minecraft-pe.cloud.bendoerr.com
#

resource "digitalocean_droplet" "minecraft-pe" {

    # image = "ubuntu-16-04-x64"
    image = ""
    name = "minecraft-pe"
    region = "nyc3"
    size = "512mb"

    backups = "false"
    ipv6 = "false"
    private_networking = true

    ssh_keys = []

    resize_disk = "false"

    tags = [ "${digitalocean_tag.servers.id}"
           , "${digitalocean_tag.minecraft-pe-servers.id}"
           ]

    connection {
        user = "root"
        type = "ssh"
        key_file = "${var.digitalocean_ssh_key}"
        timeout = "2m"
    }

}

resource "digitalocean_record" "minecraft-pe" {
    domain = "cloud.bendoerr.com"
    type = "A"
    name = "minecraft-pe"
    value = "${digitalocean_droplet.minecraft-pe.ipv4_address}"
}

resource "digitalocean_record" "minecraft-pe_internal" {
    domain = "cloud.bendoerr.com"
    type = "A"
    name = "minecraft-pe.internal"
    value = "${digitalocean_droplet.minecraft-pe.ipv4_address_private}"
}

################################################################################
#
# testing-01.cloud.bendoerr.com
#
/*
resource "digitalocean_droplet" "testing-01" {

    image = "ubuntu-16-04-x64"
    name = "testing-01"
    region = "nyc3"
    size = "512mb"

    backups = "false"
    ipv6 = "false"
    private_networking = true

    ssh_keys = [
        "${var.digitalocean_ssh_fingerprint}"
    ]

    resize_disk = "false"

    tags = [ "${digitalocean_tag.testing-servers.id}"
           ]


    provisioner "remote-exec" {
        # Force wait until ssh is ready
        inline = [ "ls" ]

        connection {
            user = "root"
            type = "ssh"
            agent = true
            timeout = "2m"
        }
    }

    provisioner "local-exec" {
        command = "cd ../manage && ANSIBLE_HOST_KEY_CHECKING=False ./bootstrap.yml -i '${digitalocean_droplet.testing-01.ipv4_address}, ' --private-key '${var.digitalocean_ssh_key}'"
    }

}

resource "digitalocean_record" "testing-01" {
    domain = "cloud.bendoerr.com"
    type = "A"
    name = "testing-01"
    value = "${digitalocean_droplet.testing-01.ipv4_address}"
}

resource "digitalocean_record" "testing-01_internal" {
    domain = "cloud.bendoerr.com"
    type = "A"
    name = "testing-01.internal"
    value = "${digitalocean_droplet.testing-01.ipv4_address_private}"
}
*/
