#! /usr/bin/env bash
#
# Personal Server Setup Script
#  - Hardens SSH
#  - Creates a local users
#  - Configures fail2ban & tripwire
#

################################################################################
# Script Behavior

# Bail on error
set -o errexit

# Declare variables first
set -o nounset

shopt -s extglob

# Debug Logging
# Trace Loggin, must be first argument
if [[ "${1:-}" == "--trace" ]]; then
    set -x
    shift
fi


################################################################################
# Variables

# Script Invocation Info
readonly SCRIPT_INVOKE="$0"
readonly SCRIPT_NAME=`basename "$0"`
readonly SCRIPT_ABS_PATH="$( [[ "${SCRIPT_INVOKE:0:1}" == "/" ]] \
                                && dirname "$SCRIPT_INVOKE" \
                                || dirname "$(pwd)/$SCRIPT_INVOKE" )"

# Grep command could be either grep or ggrep
GREP=

# For consistency and sanity
readonly TRUE=0
readonly FALSE=1

readonly LOGFILE="setup.log"

# Host Name
readonly HOSTNAME="$(uname -n)"
readonly HOSTDOMAIN="cloud.bendoerr.com"
readonly INTRDOMAIN="internal.$HOSTDOMAIN"
readonly HOSTFQDN="$HOSTNAME.$HOSTDOMAIN"
readonly INTRFQDN="$HOSTNAME.$INTRDOMAIN"

readonly DEFAULT_MAILHOST="gateway.internal.cloud.bendoerr.com"
readonly DEFAULT_EMAIL_TEST_ADDR="admin@$HOSTNAME <craftsman@bendoerr.me>"
readonly DEFAULT_EMAIL_DEST="craftsman@bendoerr.me"

# Paths
readonly SSH_ETC="/etc/ssh"
readonly TMPL_PATH="$SCRIPT_ABS_PATH"
readonly ABIN_PATH="$SCRIPT_ABS_PATH"

readonly EDITOR_PATH="/usr/bin/vim.basic"
readonly HOME_ROOT="/home"
readonly HOSTS_FILE="/etc/hosts"
readonly SHADOW_FILE="/etc/shadow"
readonly SSHD_CONFIG="$SSH_ETC/sshd_config"
readonly SSHD_CONFIG_TEMPLATE="$TMPL_PATH/sshd_config.tmpl"
readonly SSHD_HOST_KEY_GLOB="$SSH_ETC/ssh_host*"
readonly SSH_ROOT_AUTH_KEYS="/root/.ssh/authorized_keys"
readonly SSH_USER_AUTH_KEYS_PERM=600
readonly SSH_USER_PATH_PERM=700
readonly DMA_ARCHIVE="$ABIN_PATH/dma-v0.11.tgz"
readonly USR_SRC="/usr/src"
readonly DMA_SRC="$USR_SRC/dma-v0.11"
readonly DMA_CONFIG="/etc/dma/dma.conf"
readonly F2B_JAIL_CONF="/etc/fail2ban/jail.conf"
readonly F2B_JAIL_LOCAL="/etc/fail2ban/jail.local"

function HOME_USER() { echo -n "$HOME_ROOT/$1"; }
function SSHD_HOST_KEY() { echo -n "$SSH_ETC/ssh_host_$1_key"; }
function SSH_USER_AUTH_KEYS() { echo -n "$(SSH_USER_PATH $1)/authorized_keys"; }
function SSH_USER_PATH() { echo -n "$(HOME_USER $1)/.ssh"; }

readonly EXPECTED_CMDS=( "sed" "update-alternatives" "ssh-keygen" "groupadd" "usermod" )
readonly EXPECTED_PATHS=( "$EDITOR_PATH" "$SSH_ETC" "$SSHD_CONFIG" "$SSHD_CONFIG_TEMPLATE" "$DMA_ARCHIVE")

# Supported SSH Host Key Type and Users
readonly SSH_HOST_KEY_TYPES=( "rsa" "ed25519" )
readonly SSH_USER_GROUP="ssh-user"

# Default Crypt Hashes
readonly DEFAULT_ROOT_HASH=''
readonly DEFAULT_USER_HASH=''

# Default Users
readonly DEFAULT_USERS=( "bdoerr" "app" )
readonly DEFAULT_SUDOERS=( "bdoerr" )


# Script Operations
setup_check=$TRUE
setup_env=$FALSE
setup_ssh=$FALSE
setup_users=$FALSE
setup_email=$FALSE
setup_fail2ban=$FALSE
setup_tripwire=$FALSE

ignore_failure=
skip_ssh_key_regen=$FALSE

################################################################################
# Usage

function usage() {
    cat 1>&2 <<EOF
$(basename "$0") [--help]
$(basename "$0") [--all | --env --ssh]

OPERATIONS
-a, --all               Run everything
                        This implies --env, --ssh, --users

-e, --env               Tweak the environment

-h, --help              Print this message

-s, --ssh               Harden SSH

-u, --users             Setup local users

EOF
}

################################################################################
# Options

if [ $# == 0 ]; then
    usage
    exit 1;
fi

while [[ $# > 0 ]]; do
    opt="$1"
    case $opt in
        -a|--all)
            setup_env=$TRUE
            setup_ssh=$TRUE
            setup_users=$TRUE
            setup_email=$TRUE
            setup_fail2ban=$TRUE
            #setup_tripwire=$TRUE
            ;;
        -e|--env)
            setup_env=$TRUE
            ;;
        -m|--email)
            setup_email=$TRUE
            ;;
        -f|--firewall)
            setup_fail2ban=$TRUE
            ;;
        -i|--ids)
            setup_tripwire=$TRUE
            ;;
        -s|--ssh)
            setup_ssh=$TRUE
            ;;
        -u|--users)
            setup_users=$TRUE
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        --check)
            ;;
        --no-check)
            setup_check=$FALSE
            ;;

        --ignore-prerequisites)
            ignore_failure=$TRUE
            ;;
        --skip-ssh-key-regen)
            skip_ssh_key_regen=$TRUE;
            ;;
        *)
            echo "Unkown option $opt" 1>&2
            usage
            exit 1
            ;;
    esac
    shift
done

################################################################################
# Util Functions

## Logging
#
# This uses a trick to move the cursor back up a line and then erase that line
# to provide verbose status updates in case something fails but to keep status
# messages compact under the expected cases.
#
# There are two versions 'update' which will be overwritten by the next message
# and 'done' which will not be overwritten.

# Formatting
readonly cupcel="$(tput cuu1)$(tput el)"
readonly mark_check="✔︎"
readonly mark_cross="✘"
readonly mark_skip="_"
readonly mark_none=" "

function status_heading() {
    echo ""   | tee -a $LOGFILE
    echo "$1" | tee -a $LOGFILE
    echo ""   | tee -a $LOGFILE
}

function status_update() {
    local msg="$1"
    local mark="${2-$mark_none}"
    echo -e "$cupcel [$mark] $msg" | tee -a $LOGFILE
}

function status_done() {
    local msg="$1"
    local mark="$2"
    echo -e "$cupcel [$mark] $msg\n" | tee -a $LOGFILE
}


################################################################################
# Prerequisite Functions

function pre_check_root() {
    status_update "Checking if run as root"
    # Must be run as root
    if [ $(id -u) -ne 0 ]; then
        status_done "Script must be run as root" $mark_cross
        test $ignore_failure || exit 1
    else
        status_done "Running as root" $mark_check
    fi
}

function pre_check_expected_paths() {
    local missing=()
    local i=1
    local expected_path=
    for expected_path in "${EXPECTED_PATHS[@]}"; do
        status_update "Checking expected paths $i/${#EXPECTED_PATHS[@]}"
        if [ ! -e $expected_path ]; then
            missing+=($expected_path)
        fi
        ((i++))
    done

    if [[ "${#missing[@]}" > 0 ]]; then
        local missing_path=
        for missing_path in "${missing[@]}"; do
            status_done "Path Not Found: $missing_path" $mark_cross
        done
        test $ignore_failure || exit 1
    else
        status_done "Found all expected paths" $mark_check
    fi
}

function pre_check_utils() {
    local missing=()

    status_update "Checking for GNU Grep"
    if ! command -v grep > /dev/null 2>&1; then
        missing+=("GNU Grep")
    else
        if grep --version | grep GNU > /dev/null 2>&1; then
            GREP=grep
        elif ggrep --version | grep GNU > /dev/null 2>&1; then
            GREP=ggrep
        else
            missing+="GNU Grep"
        fi
    fi

    local i=1
    local expected_cmd=
    for expected_cmd in "${EXPECTED_CMDS[@]}"; do
        status_update "Checking expected command $i/${#EXPECTED_CMDS[@]}"
        if ! command -v $expected_cmd > /dev/null 2>&1; then
            missing+=($expected_cmd)
        fi
        ((i++))
    done

    if [[ "${#missing[@]}" > 0 ]]; then
        local missing_cmd=
        for missing_cmd in "${missing[@]}"; do
            status_done "Command Not Found: $missing_cmd" $mark_cross
        done
        test $ignore_failure || exit 1
    else
        status_done "Found all required commands" $mark_check
    fi
}

function run_prerequisite() {
    echo "Started $(date)" > $LOGFILE

    if [ $setup_check -eq $FALSE ]; then
        return
    fi

    status_heading "Prerequisites"

    pre_check_root
    pre_check_expected_paths
    pre_check_utils
}

################################################################################
# Env Functions

function env_set_editor() {
    status_update "Setting editor alterative as $EDITOR_PATH"

    local current=$(update-alternatives --query editor \
                        | $GREP -o -P '(?<=Value: ).*')
    if [[ "$current" == "$EDITOR_PATH" ]]; then
        status_done "Editor already set" $mark_check
    else
        update-alternatives --set editor "$EDITOR_PATH" 2>&1 >> $LOGFILE
        status_done "Editor set" $mark_check
    fi
}

function env_add_fqdn_to_hosts() {
    status_update "Updating /etc/hosts with domain names"
    local public_ip="$(ip addr show eth0 | grep -m 1 -o -P "(?<=inet )[^/]*")"
    local private_ip="$(ip addr show eth1 | grep -m 1 -o -P "(?<=inet )[^/]*")"

    # Fix the default duplicated shortname
    # sed -i -E "0,/^(127.0.1.1).*/{s//\1 $HOSTNAME/}" $HOSTS_FILE >> $LOGFILE
    sed -i -E "/^(127.0.1.1).*/d" $HOSTS_FILE >> $LOGFILE

    if grep "$HOSTFQDN" $HOSTS_FILE > /dev/null 2>&1; then
        status_done "File $HOSTS_FILE already has $HOSTFQDN" $mark_check
    else
        echo "$public_ip $HOSTFQDN $HOSTNAME" >> $HOSTS_FILE
        status_done "File $HOSTS_FILE updated with $HOSTFQDN" $mark_check
    fi

    if grep "$INTRFQDN" $HOSTS_FILE > /dev/null 2>&1; then
        status_update ""
        status_done "File $HOSTS_FILE already has $INTRFQDN" $mark_check
    else
        echo "$private_ip $INTRFQDN" >> $HOSTS_FILE
        status_update ""
        status_done "File $HOSTS_FILE updated with $INTRFQDN" $mark_check
    fi
}


function run_env() {
    if [ $setup_env -eq $FALSE ]; then
        return
    fi

    status_heading "Configuring Environment"

    env_set_editor
    env_add_fqdn_to_hosts
}


################################################################################
# SSH Hardening Functions

function ssh_regenerate_host_keys() {
    if [ $skip_ssh_key_regen -eq $TRUE ]; then
        return
    fi

    status_update "Checking for SSHD host keys"
    local has_host_keys=$FALSE
    local f=
    for f in $SSHD_HOST_KEY_GLOB; do
        [ -e "$f" ] && has_host_keys=$TRUE
        break
    done

    if [ $TRUE == $has_host_keys ]; then
        status_update "Removing old SSHD host keys"
        rm -v $SSHD_HOST_KEY_GLOB >> $LOGFILE 2>&1
    else
        status_update "No SSHD host keys found"
    fi

    status_update "Generating 4096-bit RSA host key"
    ssh-keygen -t "rsa" \
               -b 4096 \
               -N "" \
               -C "$HOSTFQDN" \
               -f "$(SSHD_HOST_KEY "rsa")" >> $LOGFILE 2>&1

    status_update "Generating Ed25519 host key"
    ssh-keygen -t "ed25519" \
               -N "" \
               -C "$HOSTFQDN" \
               -f "$(SSHD_HOST_KEY "ed25519")" >> $LOGFILE 2>&1

    status_done "Generated new RSA and Ed25519 host keys" $mark_check
}

function ssh_configure() {
    status_update "Configuring sshd_config"
    cp -v $SSHD_CONFIG_TEMPLATE $SSHD_CONFIG 2>&1 >> $LOGFILE
    status_done "Configured sshd_config" $mark_check
}

function ssh_user_group() {
    status_update "Setting up group for allowed SSH users"

    # Create the group if needed
    if getent group $SSH_USER_GROUP > /dev/null; then
        status_update "Group is already setup"
    else
        groupadd "$SSH_USER_GROUP" 2>&1 >> $LOGFILE
        status_update "Group $SSH_USER_GROUP created"
    fi

    # Add root to the user group if needed
    if groups root | grep "\b$SSH_USER_GROUP\b" > /dev/null; then
        status_update "Root is in $SSH_USER_GROUP"
    else
        usermod -a -G "$SSH_USER_GROUP" root 2>&1 >> $LOGFILE
        status_update "Root added to group $SSH_USER_GROUP"
    fi

    status_done "SSH user group ready" $mark_check
}

function ssh_reconfig() {
    status_update "Forcing SSHD to reload config"
    kill -SIGHUP $(cat /var/run/sshd.pid) 2>&1 >> /dev/null
    status_done "SSHD config reloaded" $mark_check
}

function run_ssh() {
    if [ $setup_ssh -eq $FALSE ]; then
        return
    fi

    status_heading "Hardening SSH"

    ssh_regenerate_host_keys
    ssh_configure
    ssh_user_group
    ssh_reconfig
}

################################################################################
# Local User Setup Functions

function users_root_password() {
    status_update "Setting roots password"

    if grep "^root:$DEFAULT_ROOT_HASH:" $SHADOW_FILE > /dev/null; then
        status_done "Password hash for root already set" $mark_check
    else
        sed -i -E "s/^root:[^:]\+:/root:$DEFAULT_ROOT_HASH:/" \
            $SHADOW_FILE >> $LOGFILE 2>&1
        status_done "Password for root set" $mark_check
    fi
}

function users_create_local() {
    status_update "Creating local users"

    local user=
    for user in "${DEFAULT_USERS[@]}"; do
        if getent passwd "$user" > /dev/null 2>&1; then
            status_update "User $user exists"
        else
            adduser --home "$HOME_ROOT/$user" \
                    --disabled-password \
                    --gecos "" "$user" >> $LOGFILE
            status_update "Created user $user"
        fi

        if groups "$user" | grep "\b$SSH_USER_GROUP\b" > /dev/null 2>&1; then
            status_update "User $user is in $SSH_USER_GROUP"
        else
            usermod -a -G "$SSH_USER_GROUP" $user 2>&1 >> $LOGFILE
            status_update "User $user added to group $SSH_USER_GROUP"
        fi

        if grep "^$user:$DEFAULT_USER_HASH:" $SHADOW_FILE > /dev/null 2>&1; then
            status_update "Password hash for $user already set"
        else
            usermod -p "" "$user" >> $LOGFILE 2>&1
            sed -i -e "s/^$user:[^:]*:/$user:$DEFAULT_USER_HASH:/" \
                $SHADOW_FILE >> $LOGFILE 2>&1
            status_update "Password for $user set"
        fi

        mkdir -v -p "$(SSH_USER_PATH $user)" >> $LOGFILE 2>&1
        cp -v $SSH_ROOT_AUTH_KEYS $(SSH_USER_AUTH_KEYS $user)  >> $LOGFILE 2>&1
        chmod -v $SSH_USER_PATH_PERM $(SSH_USER_PATH $user) >> $LOGFILE 2>&1
        chmod -v $SSH_USER_AUTH_KEYS_PERM $(SSH_USER_AUTH_KEYS $user) >> $LOGFILE 2>&1
        chown -v -R $user:$user $(HOME_USER $user) >> $LOGFILE 2>&1
        status_update "Installed authorized_keys for $user"

        status_done "User $user is setup" $mark_check
    done
}

function users_sudo() {
    status_update "Setting up sudoers"

    for user in "${DEFAULT_SUDOERS[@]}"; do
        if ! groups "$user" | grep "\badmin\b" > /dev/null 2>&1; then
            usermod -a -G admin $user >> $LOGFILE 2>&1
        fi
    done

    if ! grep "mailfrom" /etc/sudoers > /dev/null 2>&1; then
        cp /etc/sudoers /tmp/sudoers >> $LOGFILE 2>&1
        awk -i inplace \
            "FNR==NR{ if (/^Defaults/) p=NR; next} 1; FNR==p{ print \"Defaults        mailfrom=\\\"$HOSTNAME@$HOSTDOMAIN\\\"\" }" \
            /tmp/sudoers /tmp/sudoers >> $LOGFILE 2>&1;
        VISUAL="cp /tmp/sudoers" visudo -f /etc/sudoers
    fi

    status_done "Sudoers are setup" $mark_check
}

function run_users() {
    if [ $setup_users -eq $FALSE ]; then
        return
    fi

    status_heading "Local User Setup"

    users_root_password
    users_create_local
    users_sudo
}

################################################################################
# Install/Configure DragonFly Lightweight MTA

# Install DMA
# apt install gcc bison flex libssl-dev make
# git clone https://github.com/corecode/dma.git
# cd dma
# make
# make install sendmail-link mailq-link install-spool-dirs install-etc
# in /etc/dma/dma.conf
#   set SMARTHOST gateway.internal.bendoerr.com
#   set MAILNAME test-dma.bendoerr.com

function email_install_dma() {
    status_update "Installing DMA"

    if ! command -v dma > /dev/null 2>&1; then

        if ! command -v make > /dev/null 2>&1; then
            status_update "Installing Make"
            apt install -y make >> $LOGFILE 2>&1;
        fi

        status_update "Installing DMA"
        tar --extract \
            --file "$DMA_ARCHIVE" \
            --directory "$USR_SRC" \
            --warning=no-unknown-keyword \
            --verbose >> $LOGFILE 2>&1

        cd "$DMA_SRC"
        make install sendmail-link mailq-link install-spool-dirs install-etc >> $LOGFILE 2>&1;

        status_done "Installed DMA" $mark_check
    else
        status_done "Already have DMA" $mark_check
    fi
}

function email_configure_dma() {
    status_update "Configuring DMA"

    if grep -E "^#SMARTHOST" $DMA_CONFIG >> /dev/null; then
        sed -i -E "s/^#(SMARTHOST).*/\1 $DEFAULT_MAILHOST/g" $DMA_CONFIG >> $LOGFILE 2>&1
        status_update "Set SMARTHOST to $DEFAULT_MAILHOST"
    else
        status_update "Has SMARTHOST set"
    fi

    if grep -E "^#MAILNAME" $DMA_CONFIG >> /dev/null; then
        sed -i -E "s/^#(MAILNAME).*/\1 $HOSTFQDN/g" $DMA_CONFIG >> $LOGFILE 2>&1
        status_update "Set MAILNAME to $HOSTFQDN"
    else
        status_update "Has MAILNAME set"
    fi

    if grep -E "^MASQUERADE" $DMA_CONFIG >> /dev/null; then
        status_update "Has MASQUERADE set"
    else
        awk -i inplace \
            "FNR==NR{ if (/# MASQUERADE/) p=NR; next} 1; FNR==p{ print \"MASQUERADE $HOSTNAME@$HOSTDOMAIN\" }" \
            $DMA_CONFIG $DMA_CONFIG >> $LOGFILE 2>&1
        status_update "Set MASQUERADE to $HOSTNAME@$HOSTDOMAIN"
    fi

    if [ ! -f /etc/aliases ]; then
        echo "*: $DEFAULT_EMAIL_DEST" > /etc/aliases
    fi

    status_done "DMA is Configured" $mark_check
}

function email_send_test() {
    status_update "Sending test email"
    sendmail -t <<EOF >> $LOGFILE 2>&1
To: $DEFAULT_EMAIL_TEST_ADDR
Subject: MTA Test from $HOSTFQDN

$(date)

Hello,

This is a test message to make sure the MTA at $HOSTFQDN is setup correctly.

Best Regards,
$(whoami)@$HOSTFQDN
EOF
    status_done "Test email sent" $mark_check
}

function email_fix_deb_mta() {
    status_update "Installing lsb-invalid-mta since we built dma from source."
    apt install -y lsb-invalid-mta >> $LOGFILE 2>&1
    if [ ! -L /usr/sbin/sendmail ]; then
        rm /usr/sbin/sendmail >> $LOGFILE 2>&1
        ln -s /usr/local/sbin/sendmail /usr/sbin/sendmail >> $LOGFILE 2>&1
    fi
    status_done "Apt has a mta now" $mark_check
}

function run_email() {
    if [ $setup_email -eq $FALSE ]; then
        return
    fi

    status_heading "Email Setup"

    email_install_dma
    email_configure_dma
    email_send_test
    email_fix_deb_mta
}

################################################################################
# Fail2Ban

function fail2ban_install() {
    status_update "Installing fail2ban firewall"
    if command -v fail2ban-client > /dev/null 2>&1; then
        status_done "Already installed fail2ban" $mark_check
    else
        apt install -y fail2ban >> $LOGFILE 2>&1;
        status_done "Installed fail2ban firewall" $mark_check
    fi
}

function fail2ban_configure() {
    status_update "Configuring fail2ban"

    cp -v $F2B_JAIL_CONF $F2B_JAIL_LOCAL >> $LOGFILE 2>&1
    sed -i -E "s/^(destemail = ).*/\1$DEFAULT_EMAIL_DEST/" $F2B_JAIL_LOCAL >> $LOGFILE 2>&1
    sed -i -E "s/^(sender = ).*/\1$HOSTNAME@$HOSTDOMAIN/" $F2B_JAIL_LOCAL >> $LOGFILE 2>&1
    sed -i -E "s/^(action = ).*/\1%(action_mwl)s/" $F2B_JAIL_LOCAL >> $LOGFILE 2>&1

    if [[ "$(command -v sendmail)" != "/usr/sbin/sendmail" ]]; then
        status_update "Fixing sendmail path"
        for f in "$(grep -R -l sendmail /etc/fail2ban/action.d)"; do
            sed -i -E "s|/usr/sbin/sendmail|$(command -v sendmail)|g" $f >> $LOGFILE 2>&1
        done
    fi

    status_update "Restarting fail2ban"
    service fail2ban restart >> $LOGFILE 2>&1

    status_done "Configured fail2ban" $mark_check
}

function run_fail2ban() {
    if [ $setup_fail2ban -eq $FALSE ]; then
        return
    fi

    status_heading "Fail2Ban Setup"

    fail2ban_install
    fail2ban_configure
}

################################################################################
# Tripwire
# I get lazy here. Tripwire is a bear to setup in an automated way.

function tripwire_install() {
    status_update "Installing Tripwire"

    if command -v tripwire > /dev/null 2>&1; then
        status_done "Already installed tripwire" $mark_check
    else
        status_done "Installing Tripwire Interactive" $mark_check
        apt install -y tripwire postfix-
    fi
}

function tripwire_config() {
    status_update "Configuring Tripwire"
    tripwire --init || true | tee $LOGFILE
    ./twpol_autocfg.sh >> $LOGFILE 2>&1
    mv -v /etc/tripwire/twpol.txt /etc/tripwire/twpol.txt.bak.$(date '+%s') >> $LOGFILE 2>&1
    mv -v /etc/tripwire/new_twpol.txt /etc/tripwire/twpol.txt >> $LOGFILE 2>&1
    sed -i -E "s|/proc\b|#/proc|g" /etc/tripwire/twpol.txt >> $LOGFILE 2>&1
    sed -i -E "s|^(MAILMETHOD.*=).*$|\1SENDMAIL|g" /etc/tripwire/twcfg.txt >> $LOGFILE 2>&1
    sed -i -E "s|^(SMTPHOST.*=).*$|MAILPROGRAM   =/usr/local/sbin/sendmail -oi -t|g" /etc/tripwire/twcfg.txt >> $LOGFILE 2>&1
    sed -i -E "s|(rulename = .*,)$|\1 emailto=craftsman@bendoerr.me,|g" /etc/tripwire/twpol.txt >> $LOGFILE 2>&1
    twadmin -m P /etc/tripwire/twpol.txt | tee $LOGFILE
    twadmin -m F --site-keyfile /etc/tripwire/site.key /etc/tripwire/twcfg.txt | tee $LOGFILE
    tripwire --init || true | tee $LOGFILE
    tripwire --check --quiet --email-report

    echo
    echo
    status_done "Tripwire Configured" $mark_check
}

function run_tripwire() {
    if [ $setup_tripwire -eq $FALSE ]; then
        return
    fi

    status_heading "Tripwire Setup"

    tripwire_install
    tripwire_config
}

################################################################################
# Business


run_prerequisite
run_env
run_ssh
run_users
run_email
run_fail2ban
run_tripwire

status_heading "Finished"
