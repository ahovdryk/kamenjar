#!/bin/bash
set -e
set -u
set -o pipefail
###############################################################################
export str_module_distress_version="0.0.1"
###############################################################################
export script_path="$HOME/kamenjar"
export script_distress="null"
###############################################################################
export link_distress_x32="https://github.com/Yneth/distress-releases/releases/latest/download/distress_i686-unknown-linux-musl"
export link_distress_x64="https://github.com/Yneth/distress-releases/releases/latest/download/distress_x86_64-unknown-linux-musl"
export link_distress_arm="https://github.com/Yneth/distress-releases/releases/latest/download/distress_arm-unknown-linux-musleabi"
export link_distress_aarch64="https://github.com/Yneth/distress-releases/releases/latest/download/distress_aarch64-unknown-linux-musl"
export link_distress_aarch64_darwin="https://github.com/Yneth/distress-releases/releases/latest/download/distress_aarch64-apple-darwin"
export link_distress_x64_darwin="https://github.com/Yneth/distress-releases/releases/latest/download/distress_x86_64-apple-darwin"
###############################################################################
os_bits=$(getconf LONG_BIT)
if [ "$os_bits" != "64" ]; then
    os_bits="32"
fi
export os_bits
###############################################################################
function distress_init(){
    printf '%s' "Module distess ver $str_module_distress_version"
    get_distress
    # 0 is an "no error" Linux error code.
    # Keep your scripts clean! Use correct error codes!
    return 0
}
export -f distress_init
###############################################################################
function get_distress() {
    if [[ ! -d "$script_path/bin" ]]
    then
        mkdir -p "$script_path/bin"
    fi
    if [[ -f "$script_path/bin/distress" ]]
    then
        rm -f "$script_path/bin/distress"
    fi
    # TODO: Write an architecture guess with uname -i
    if [[ "$os_bits" == "32" ]]; then
        download_link=$link_distress_x32
    fi
    if [[ "$os_bits" == "64" ]]; then
        download_link=$link_distress_x64
    fi
    while [[ ! -f "$script_path/bin/distress" ]]; do
        wait_for_internet
        curl -s -L --retry 10 --output "$script_path/bin/distress" --url "$download_link"
        chmod +x "$script_path/bin/distress"
    done
    export script_distress="$script_path/bin/distress"
}
export -f get_distress
###############################################################################
# shellcheck disable=2317
# It seems shellcheck is not aware of trap
function distress_cleanup() {
    if [[ "$script_distress" != "null" ]]
    then
        pkill -f "$script_distress"
    fi
    if [[ -f "$script_distress" ]]
    then
        rm -f "$script_distress"
    fi
}
###############################################################################
trap distress_cleanup INT
distress_init "$@"
exit