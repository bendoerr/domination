#! /usr/bin/env bash
#

set -e

HOSTNAME="$(hostname).bendoerr.com"
ROOT_HASH=''
BDOERR_HASH=''

# Use Vim

update-alternatives --set editor /usr/bin/vim.basic

# Harden SSH

echo
echo "== Create New SSH Host Keys"
echo

SSHD_ETC="/etc/ssh"
SSHD_CONFIG="${SSHD_ETC}/sshd_config"

rm -v "$SSHD_ETC"/ssh_host_* || true

ssh-keygen -t "rsa" -b 4096 -N "" -C "$HOSTNAME" -f "$SSHD_ETC"/ssh_host_rsa_key 2>&1 > /dev/null
echo "generated '$SSHD_ETC/ssh_host_rsa_key'"

ssh-keygen -t "ed25519"     -N "" -C "$HOSTNAME" -f "$SSHD_ETC"/ssh_host_ed25519_key 2>&1 > /dev/null
echo "generated '$SSHD_ETC/ssh_host_ed25519_key'"

echo
echo "== Replacing SSHD Config"
echo

cp -v sshd_config "$SSHD_CONFIG"

echo
echo "== Add ssh-user group"
echo

groupadd ssh-user || true
echo "created group ssh-user"

echo
echo "== Harden root user"
echo

usermod -a -G ssh-user root
echo "added root to ssh-user"

sed -i -e "s/^root:[^:]\+:/root:$ROOT_HASH:/" /etc/shadow
echo "reset root password"

echo
echo "== Create normal user"
echo

adduser --home /home/bdoerr --disabled-password --gecos "" bdoerr > /dev/null || true
echo "created user bdoerr"

usermod -a -G ssh-user bdoerr
echo "added bdoerr to ssh-user"

usermod -p "" bdoerr
sed -i -e "s/^bdoerr:[^:]\+:/bdoerr:$BDOERR_HASH:/" /etc/shadow
echo "updated bdoerr password"

mkdir -p /home/bdoerr/.ssh
cp /root/.ssh/authorized_keys /home/bdoerr/.ssh/authorized_keys
chmod 700 /home/bdoerr/.ssh
chmod 600 /home/bdoerr/.ssh/authorized_keys
chown -R bdoerr:bdoerr /home/bdoerr
echo "added 'authorized_keys' to bdoerr"

echo
echo "== Setup /etc/hosts"
echo

sed -i -E "0,/^(127.0.1.1).*/{s//\1 $HOSTNAME.bendoerr.com $HOSTNAME/}" /etc/hosts
echo "added fqdn to /etc/hosts"

echo
echo "== Setup Sendmail"
echo

apt install -y sendmail mailutils sendmail-bin  2>&1 > /dev/null
echo "installed sendmail"

mkdir -m 700 -p /etc/mail/authinfo/
echo 'AuthInfo: "U:root" "I:craftsman@bendoerr.me" "P:iligeetayikqtjak"' > /etc/mail/authinfo/gmail-auth
chmod o-r /etc/mail/authinfo/gmail-auth
makemap hash /etc/mail/authinfo/gmail-auth < /etc/mail/authinfo/gmail-auth
cp sendmail.mc /etc/mail/sendmail.mc
make -C /etc/mail
/etc/init.d/sendmail reload
echo "Just testing sendmail gmail relay configuration." | mail -s "Testing Sendmail Setup" craftsman@bendoerr.me
echo "setup gmail smpt relay"

echo
echo "== Setup Fail2Ban"
echo

apt install -y fail2ban 2>&1 > /dev/null
echo "installed fail2ban"

cp -v /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i -E 's/^(destmail = ).*/\1craftsman@bendoerr.me/' /etc/fail2ban/jail.local
sed -i -E "s/^(sender = ).*/\1fail2ban@$HOSTNAME.bendoerr.com/" /etc/fail2ban/jail.local
echo "configured fail2ban"


echo
echo "== Setup Tripwire"
echo

