#!/usr/bin/env bash
#

################################################################################
# Standard Script Behavior

# Bail on cmd, pipe, variable failures
set -o errexit
set -o pipefail
set -o nounset

# Debug and Trace Logging
if [[ "${1:-}" == "--trace" ]]; then
    set -o xtrace
    shift
elif [[ "${1:-}" == "--debug" ]]; then
    set -o verbose
    shift
fi

################################################################################
# Standard Statics

# Script Invocation Info
readonly SCRIPT_INVOKE="$0"
readonly SCRIPT_NAME=`basename "$0"`
readonly SCRIPT_ABS_PATH="$( [[ "${SCRIPT_INVOKE:0:1}" == "/" ]] \
                                && dirname "$SCRIPT_INVOKE" \
                                || dirname "$(pwd)/$SCRIPT_INVOKE" )"


# For consistency and sanity with exit codes
readonly TRUE=0
readonly FALSE=1

################################################################################
# Script Statics

readonly PLAN_PATH="${SCRIPT_ABS_PATH}/tfplans"
readonly STATE_PATH="${SCRIPT_ABS_PATH}/tfstates"

readonly CURRENT_PLAN="${PLAN_PATH}/current.tfplan"
readonly CURRENT_STATE="${STATE_PATH}/current.tfstate"

################################################################################
# Script Variables


################################################################################
# Usage

function usage() {
    cat 1>&2 <<EOF
$(basename "$0") [--help]

OPTIONS

EOF
}

################################################################################
# Options

if [ $# -gt 1 ]; then
    usage
    exit 1;
fi

while [[ $# > 0 ]]; do
    opt="$1"
    case $opt in
        *)
            echo "Unkown option $opt" 1>&2
            usage
            exit 1
            ;;
    esac
    shift
done

################################################################################
# Business


function check_current_plan() {
    if [ ! -e "${CURRENT_PLAN}" ]; then
        echo -n "A current plan [tfplans/current.tfplan] does not exist."   1>&2
        exit 1
    fi
}

function new_state() {
    echo "${STATE_PATH}/$(date +%Y-%m-%d_%H-%M-%S).tfstate"
}

function link_state() {
    rm "${CURRENT_STATE}"
    ln -s "$(basename "${1}")" "${CURRENT_STATE}"
    rm "${CURRENT_PLAN}"
}

check_current_plan

readonly out_state="$(new_state)"

terraform apply \
    -state="${CURRENT_STATE}" \
    -state-out="${out_state}" \
    -backup="-" \
    "${CURRENT_PLAN}"

link_state "${out_state}"
