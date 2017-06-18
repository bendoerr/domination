################################################################################
# Standard Constants

function main() {
    # Script Invocation Info
    local -r SCRIPT_INVOKE="$0"
    local -r SCRIPT_NAME=`basename "$0"`
    local -r SCRIPT_ABS_PATH="$( [[ "${SCRIPT_INVOKE:0:1}" == "/" ]] \
                                    && dirname "$SCRIPT_INVOKE" \
                                    || dirname "$(pwd)/$SCRIPT_INVOKE" )"


    ################################################################################
    # Script Variables

    local -r OPENSSL_BIN="/usr/local/opt/openssl/bin/openssl"
    local -r OPENSSL_DEC=(
                        "enc"
                        "-aes-256-cbc"
                        "-d"
                        "-base64"
                        "-in"
                        )

    local -r DIGITALOCEAN_TOKEN_SECRET_FILE="$SCRIPT_ABS_PATH/.secrets.digitalocean_token.enc"

    ################################################################################
    # BUSINESS


    echo -n "[secrets.digitalocean_token] "
    local -r do_token="$(${OPENSSL_BIN} ${OPENSSL_DEC[@]} "${DIGITALOCEAN_TOKEN_SECRET_FILE}")"

    # For Terraform
    export DIGITALOCEAN_TOKEN="${do_token}"
    # For Ansible
    export DO_API_TOKEN="${do_token}"
}

main $0
