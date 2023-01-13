#!/bin/bash
set -e
set -u
set -o pipefail
###############################################################################
export str_module_ita_version="0.0.1"
###############################################################################
export script_path="$HOME/kamenjar"
export script_ita="null"
###############################################################################
export link_mhddos_ita_x64="https://github.com/porthole-ascend-cinnamon/mhddos_proxy_releases/releases/latest/download/mhddos_proxy_linux"
export link_mhddos_ita_arm_x64="https://github.com/porthole-ascend-cinnamon/mhddos_proxy_releases/releases/latest/download/mhddos_proxy_linux_arm64"
###############################################################################
export str_ita_no_x32="mhddos_proxy від ІТ-Армії України не має х32 версії під Linux."
export str_ita_failed="Неможливо запустити ita_mhddos_proxy. Вимкнено."
###############################################################################
os_bits=$(getconf LONG_BIT)
if [ "$os_bits" != "64" ]; then
    os_bits="32"
fi
export os_bits
###############################################################################
function ita_init(){
    printf '%s' "Module ITA ver $str_module_ita_version"
    if [[ ! -d "$script_path/bin" ]]
    then
        mkdir -p "$script_path/bin"
    fi
    if [[ $os_bits == "64" ]]
    then
        download_link=$link_mhddos_ita_x64
        if [[ -f "$script_path/bin/ita" ]]; then
            rm -f "$script_path/bin/ita"
        fi
        while [[ ! -f "$script_path/bin/ita" ]]; do
            curl -s -L --retry 10 --output "$script_path/bin/ita" --url $download_link
        done
        chmod +x "$script_path/bin/ita"
        export script_ita="$script_path/bin/ita"
    else
        printf '%s' "$str_ita_no_x32\n$str_ita_failed\n"
        # 38 is a Linux code for "Function not implemented"
        # Keep your scripts clean! Use correct error codes!
        return 38
    fi
    # 0 is an "no error" Linux error code.
    # Keep your scripts clean! Use correct error codes!
    return 0
}
export -f ita_init
###############################################################################
# shellcheck disable=2317
# It seems shellcheck is not aware of trap
function ita_cleanup() {
    if [[ "$script_ita" != "null" ]]
    then
        pkill -f "$script_ita"
    fi
    if [[ -f "$script_ita" ]]
    then
        rm -f "$script_ita"
    fi
}
###############################################################################
trap ita_cleanup INT
ita_init "$@"
exit