#!/bin/bash
set -e
set -u
set -o pipefail
###############################################################################
export str_module_wondershaper_version="0.0.1"
###############################################################################
export script_path="$HOME/kamenjar"
export script_wondershaper="null"
export script_unzip="null"
###############################################################################
export link_wondershaper="https://github.com/magnific0/wondershaper/archive/refs/heads/master.zip"
export link_unzip="https://oss.oracle.com/el4/unzip/unzip.tar"
###############################################################################
export str_wondershaper_no_root="wondershaper потребує адміністративних прав для роботи. Скрипт запущено без адміністративних прав, а в системі немає sudo."
export str_wondershaper_failed="Шейпер неможливо запустити. Вимкнено."
###############################################################################
# Do we have sudo on system?
if ! command -v sudo >/dev/null 2>&1; then
    export script_have_sudo="false"
else
    export script_have_sudo="true"
fi
# Are we root?
if [[ "$EUID" == 0 ]]; then
    export script_is_root="true"
else
    export script_is_root="false"
fi
# Get our internet interface
internet_interface=$(ip -o -4 route show to default | awk '{print $5}')
export internet_interface
###############################################################################
function wondershaper_init(){
    printf '%s' "Module wondershaper ver $str_module_wondershaper_version"
    if [[ ($script_is_root == "true") || ($script_have_sudo == true) ]]; then
        get_wondershaper
        # 0 is an "no error" Linux error code.
        # Keep your scripts clean! Use correct error codes!
        return 0
    else
        printf '%s' "$str_wondershaper_no_root\n$str_wondershaper_failed\n"
        # 1 is a Linux operation not permitted error code.
        # Keep your scripts clean! Use correct error codes!
        return 1
    fi
}
export -f wondershaper_init
###############################################################################
function get_wondershaper() {
    if [[ ! -d "$script_path/bin" ]]
    then
        mkdir -p "$script_path/bin"
    fi
    if ! command -v unzip >/dev/null 2>&1; then
        wait_for_internet
        curl -s -L --url $link_unzip --output "$script_path/unzip.tar"
        tar -xf "$script_path/unzip.tar" -C "$script_path/bin/"
        chmod +x "$script_path/bin/unzip"
        export script_unzip="$script_path/bin/unzip"
    else
        export script_unzip="unzip"
    fi
    while [[ ! -f "$script_path/bin/wondershaper" ]]; do
        wait_for_internet
        curl -s -L --url $link_wondershaper --output "$script_path/wondershaper.zip"
        $script_unzip "$script_path/wondershaper.zip" -d "$script_path" >/dev/null 2>&1
        rm -rf "$script_path/bin/wondershaper"
        mv "$script_path/wondershaper-master" "$script_path/bin/wondershaper"
        rm -f "$script_path/wondershaper.zip"
    done
}
export -f get_wondershaper
###############################################################################
# shellcheck disable=2317
# It seems shellcheck is not aware of trap
function wondershaper_cleanup() {
    if [[ $script_have_sudo ]]; then
            sudo "$script_wondershaper" -c -a "$internet_interface" || true
        elif [[ $script_is_root ]]; then
            "$script_wondershaper" -c -a "$internet_interface" || true
        fi
}
###############################################################################
trap wondershaper_cleanup INT
wondershaper_init "$@"
exit