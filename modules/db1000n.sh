#!/bin/bash
set -e
set -u
set -o pipefail
###############################################################################
export str_module_db1000n_version="0.0.1"
###############################################################################
export script_path="$HOME/kamenjar"
export script_db1000n="null"
###############################################################################
export link_db1000n_x32="https://github.com/Arriven/db1000n/releases/latest/download/db1000n_linux_386.tar.gz"
export link_db1000n_x64="https://github.com/Arriven/db1000n/releases/latest/download/db1000n_linux_amd64.tar.gz"
export link_db1000n_x64_darwin="https://github.com/Arriven/db1000n/releases/latest/download/db1000n_darwin_amd64.tar.gz"
export link_db1000n_arm_darwin="https://github.com/Arriven/db1000n/releases/latest/download/db1000n_darwin_arm64.tar.gz"
export link_db1000n_x64_freebsd="https://github.com/Arriven/db1000n/releases/latest/download/db1000n_freebsd_amd64.tar.gz"
export link_db1000n_arm_freebsd="https://github.com/Arriven/db1000n/releases/latest/download/db1000n_freebsd_arm64.tar.gz"
###############################################################################
os_bits=$(getconf LONG_BIT)
if [ "$os_bits" != "64" ]; then
    os_bits="32"
fi
export os_bits
###############################################################################
function db1000n_init(){
    printf '%s' "Module db1000n v$str_module_db1000n_version"
    get_db1000n
    # 0 is an "no error" Linux error code.
    # Keep your scripts clean! Use correct error codes!
    return 0
}
export -f db1000n_init
###############################################################################
function get_db1000n {
    if [[ ! -d "$script_path/bin" ]]
    then
        mkdir -p "$script_path/bin"
    fi
    if [[ -f "$script_path/bin/db1000n" ]]
    then
        rm -f "$script_path/bin/db1000n"
    fi
    # TODO: Write an architecture guess with uname -i
    if [[ "$os_bits" == "32" ]]; then
        download_link=$link_db1000n_x32
    fi
    if [[ "$os_bits" == "64" ]]; then
        download_link=$link_db1000n_x64
    fi
    while [[ ! -f "$script_path/bin/db1000n" ]]; do
        wait_for_internet
        curl -s -L --retry 10 --output "$script_path/bin/db1000n.tar.gz" --url "$download_link"
        tar -xzf "$script_path/bin/db1000n.tar.gz" -C "$script_path/bin/"
        rm -f "$script_path/bin/db1000n.tar.gz"
        chmod +x "$script_path/bin/db1000n"
    done
    export script_db1000n="$script_path/bin/db1000n"
}
export -f get_db1000n
###############################################################################
# shellcheck disable=2317
# It seems shellcheck is not aware of trap
function db1000n_cleanup
{
    if [[ "$script_db1000n" != "null" ]]
    then
        pkill -f "$script_db1000n"
    fi
    if [[ -f "$script_db1000n" ]]
    then
        rm -f "$script_db1000n"
    fi
}
trap db1000n_cleanup INT
db1000n_init "$@"
exit