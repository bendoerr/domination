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

var_replace_current=$FALSE

################################################################################
# Usage

function usage() {
    cat 1>&2 <<EOF
$(basename "$0") [--help]
$(basename "$0") [--replace-current]

OPTIONS
-r, --replace-current   If there is a current plan, replace that plan with the
                        new plan rather than exiting.

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
        -r|--replace-current)
            var_replace_current=$TRUE
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
# Business

function remove_old_plan() {
    local linked_current_plan=$(readlink "${CURRENT_PLAN}")
    local resolved_current_plan="$( [[ "${linked_current_plan:0:1}" == "/" ]] \
                                      && echo "${linked_current_plan}" \
                                      || echo "$(dirname "${CURRENT_PLAN}")/${linked_current_plan}" )"
    rm "${CURRENT_PLAN}"
    rm "${resolved_current_plan}"
}

function check_current_plan() {
    if [ -e "${CURRENT_PLAN}" ]; then
        if [ ! -h "${CURRENT_PLAN}" ]; then
            echo -n "The current plan [tfplans/current.tfplan] is not symlink " 1>&2
            echo    "which wouldn't have been created by this script."          1>&2
            echo    "Remove it before continuing."                              1>&2
            exit 1
        fi

        if [ "${var_replace_current}" -eq "${FALSE}" ]; then
            echo    "A current plan [tfplans/current.tfplan] exists."           1>&2
            echo -n "Run the 'apply.sh' script to apply the plan or run this "  1>&2
            echo    "script with the '--replace-current' flag to replace it"    1>&2
            exit 1
        fi

        echo -n "A current plan [tfplans/current.tfplan] exists. It will be "
        echo    "replaced with a new plan."
        remove_old_plan
    fi
}

function mk_new_plan() {
    local now_plan="${PLAN_PATH}/$(date +%Y-%m-%d_%H-%M-%S).tfplan"
    touch "${now_plan}"
    ln -s "$(basename "${now_plan}")" "${CURRENT_PLAN}"
}

check_current_plan
mk_new_plan


set +o errexit
terraform plan \
    -out="${CURRENT_PLAN}" \
    -state="${CURRENT_STATE}" \
    -detailed-exitcode
readonly plan_exit="$?"
set -o errexit

if [ "${plan_exit}" -eq "0" ] || [ "${plan_exit}" -eq "1" ]; then
    remove_old_plan
fi
