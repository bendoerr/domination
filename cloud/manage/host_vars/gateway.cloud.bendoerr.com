---
host_certs_names:
  - cloud.bendoerr.com
  - gateway.cloud.bendoerr.com

postfix_gateway_mta_admin_email: craftsman@bendoerr.me
postfix_gateway_mta_origin: cloud.bendoerr.com

postfix_gateway_mta_tls_cert_file: /etc/letsencrypt/live/cloud.bendoerr.com/fullchain.pem
postfix_gateway_mta_tls_key_file: /etc/letsencrypt/live/cloud.bendoerr.com/privkey.pem

postfix_gateway_mta_networks: 127.0.0.0/8 10.132.0.0/16
postfix_gateway_mta_smtp_bind: "{{ ansible_eth0['ipv4'].address }}"
postfix_gateway_mta_inet_interfaces: "{{ ansible_eth1['ipv4'].address }}"
postfix_gateway_mta_inet_protocols: ipv4

