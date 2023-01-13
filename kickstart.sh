#!/bin/bash
set -e
set -u
set -o pipefail
###############################################################################
export str_kickstart_version="0.0.1"
###############################################################################
export script_path="$HOME/kamenjar"
###############################################################################
function check_internet() {
    cat </dev/null >/dev/tcp/8.8.8.8/53
    local online=$?
    if [[ $online -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}
export -f check_internet
###############################################################################
function wait_for_internet {
    check_internet
    local have_internet=$?
    # minute=0
    while [[ ! $have_internet ]]; do
        sleep $((1 + RANDOM % 10))
        have_internet=$(check_internet)
        if [[ ! $have_internet ]]; then
            true
            # TODO: Some message, maybe?
        fi
    done
}
export -f wait_for_internet
################################################################################
# shellcheck disable=2317
# It seems shellcheck is not aware of trap
function cleanup_kickstart {
    if [[ -f "$script_path/main.sh" ]]
    then
        rm -f "$script_path/main.sh"
    fi
}
export -f cleanup_kickstart
################################################################################
function kickstart(){
    printf '%s' "Kickstart ver $str_kickstart_version"
    while true
    do
        wait_for_internet
        curl s -L --url "https://raw.githubusercontent.com/ahovdryk/kamenjar/main/main.sh" --output "$script_path/main.sh"
        bash "$script_path/main.sh" "$@"
        rm -f "$script_path/main.sh"
    done
}
export -f kickstart
################################################################################
trap cleanup_kickstart INT
kickstart "$@"
exit