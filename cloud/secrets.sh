################################################################################
# Standard Constants

# Script Invocation Info
readonly SCRIPT_INVOKE="$0"
readonly SCRIPT_NAME=`basename "$0"`
readonly SCRIPT_ABS_PATH="$( [[ "${SCRIPT_INVOKE:0:1}" == "/" ]] \
                                && dirname "$SCRIPT_INVOKE" \
                                || dirname "$(pwd)/$SCRIPT_INVOKE" )"


################################################################################
# Script Variables

readonly OPENSSL_BIN="/usr/local/opt/openssl/bin/openssl"
readonly OPENSSL_DEC=(
                     "enc"
                     "-aes-256-cbc"
                     "-d"
                     "-base64"
                     "-in"
                     )

readonly DIGITALOCEAN_TOKEN_SECRET_FILE="$SCRIPT_ABS_PATH/.secrets.digitalocean_token.enc"

################################################################################
# BUSINESS


echo -n "[secrets.digitalocean_token] "
readonly do_token="$(${OPENSSL_BIN} ${OPENSSL_DEC[@]} "${DIGITALOCEAN_TOKEN_SECRET_FILE}")"

# For Terraform
export DIGITALOCEAN_TOKEN="${do_token}"
# For Ansible
export DO_API_TOKEN="${do_token}"
