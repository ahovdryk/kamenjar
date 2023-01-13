#!/bin/bash
set -e
set -u
set -o pipefail
###############################################################################
export str_module_cloudflare_version="0.0.1"
###############################################################################
export script_path="$HOME/kamenjar"
###############################################################################
export link_shtools="ftp://ftp.gnu.org/gnu/shtool/shtool-2.0.8.tar.gz"
export link_cf_centos8="https://pkg.cloudflareclient.com/cloudflare-release-el8.rpm"
###############################################################################
export str_cloudflare_no_root="CF Warp потребує адміністративних прав для інсталляції. Скрипт запущено без адміністративних прав, а в системі немає sudo."
export str_cloudflare_wrong_os="Ця операційна система не підтримується."
export str_cloudflare_failed="CF Warp неможливо запустити. Вимкнено."
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
###############################################################################
function cloudflare_init(){
    cf_good_to_go="false"
    cf_installed="false"
    if command -v warp-cli >/dev/null 2>&1; then
        cf_installed="true"
        cf_good_to_go="true"
    fi
    if [[ "$cf_installed" != "true" ]]
    then
        if [[ ($script_is_root == "true") || ($script_have_sudo == true) ]]; then
            if [[ $script_have_sudo == "true" ]]
            then
                sudo cp /etc/resolv.conf "$script_path/resolv.conf.backup"
            elif [[ $script_is_root == "true" ]]
            then
                cp /etc/resolv.conf "$script_path/resolv.conf.backup"
            fi
            get_cloudflare
            local error_code=$?
            # 38 is a Linux code for "Function not implemented"
            # Keep your scripts clean! Use correct error codes!
            if [[ $error_code -eq 38 ]]
            then
                printf '%s' "$str_cloudflare_wrong_os\n$str_cloudflare_failed\n"
                return 38
            fi
            if [[ $error_code -eq 0 ]]
            then
                return 0
            fi
        else
            printf '%s' "$str_cloudflare_no_root\n$str_cloudflare_failed\n"
            # 1 is a Linux operation not permitted error code.
            # Keep your scripts clean! Use correct error codes!
            return 1
        fi
    fi

}
export -f cloudflare_init
###############################################################################
# shellcheck disable=2034
function get_cloudflare() {
    local plat_tool="$script_path/bin/shtool-2.0.8/sh.platform"
    local output_path="$script_path/bin/shtools.tar.gz"
    local shtools_path="$script_path/bin/shtool-2.0.8/"
    if [[ ! -d "$script_path/bin" ]]
    then
        mkdir -p "$script_path/bin"
    fi
    wait_for_internet
    while [[ ! -f $plat_tool ]]; do
        curl -s -L --retry 10 --output "$output_path" --url $link_shtools --disable-epsv >/dev/null 2>&1
        tar -xzf "$output_path" -C "$script_path/bin/" >/dev/null 2>&1
        rm -f "$output_path" >/dev/null 2>&1
    done
    local plat_output
    cd "$shtools_path"
    plat_output=$(bash "$plat_tool" -v -F "%[at] %{sp} %[st]")
    cd "$script_path"
    local rest=$plat_output
    os_arch="${rest%% *}"
    rest="${rest#* }"
    os_dist="${rest%% *}"
    rest="${rest#* }"
    os_version="${rest%% *}"
    rest="${rest#* }"
    os_family="${rest%% *}"
    rest="${rest#* }"
    os_kernel="${rest%% *}"
    os_kernel="${os_kernel///}"
    os_version_major="${os_version%.*}"

    if [[ "$os_dist" == "CentOS" || $os_dist == "centos" ]]; then
        if [[ "$os_version_major" == "8" ]]; then
            cf_good_to_go="true"
            wait_for_internet
            sudo rpm -ivh "$link_cf_centos8"
            sudo yum update
            sudo yum -y install cloudflare-warp
            yes | warp-cli register || true
        else
            cf_good_to_go="false"
        fi
    elif [[ "$os_dist" == "Ubuntu" && $os_version_major -ge 16 ]]; then
        cf_good_to_go="true"
        local gpg="/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg"
        wait_for_internet
        curl -s https://pkg.cloudflareclient.com/pubkey.gpg |
            sudo gpg --yes --dearmor --output $gpg
        wait_for_internet
        echo "deb [arch=amd64 signed-by=$gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" |
            sudo tee /etc/apt/sources.list.d/cloudflare-client.list
        wait_for_internet
        sudo apt update
        wait_for_internet
        sudo apt -y install cloudflare-warp
        yes | warp-cli register || true
    elif [[ "$os_dist" == "Debian" && $os_version_major -ge 9 ]]; then
        cf_good_to_go="true"
        local gpg="/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg"
        wait_for_internet
        curl -s https://pkg.cloudflareclient.com/pubkey.gpg |
            sudo gpg --yes --dearmor --output $gpg
        wait_for_internet
        echo "deb [arch=amd64 signed-by=$gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" |
            sudo tee /etc/apt/sources.list.d/cloudflare-client.list
        wait_for_internet
        sudo apt update
        wait_for_internet
        sudo apt -y install cloudflare-warp
        yes | warp-cli register || true
    else
        cf_good_to_go="false"
        # 38 is a Linux code for "Function not implemented"
        # Keep your scripts clean! Use correct error codes!
        return 38
    fi


}
export -f get_cloudflare
###############################################################################
# shellcheck disable=2317
# It seems shellcheck is not aware of trap
function restore_dns() {
    wait_for_internet
    if check_dns; then
        return 0
    else
        cat >"$script_path/resolv.conf" <<'EOF'
# This file was generated by multiddos
nameserver 127.0.2.2
nameserver 127.0.2.3
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 50.230.4.242
nameserver 104.244.141.140
nameserver 98.232.103.4
nameserver 23.28.169.42
nameserver 24.60.77.38
nameserver 50.217.217.126
nameserver 98.238.242.50
nameserver 209.242.60.162
nameserver 73.222.26.229
nameserver 73.4.55.103
nameserver 172.74.55.84
nameserver 70.191.183.15
nameserver fd01:db8:1111::2
nameserver fd01:db8:1111::3
search .
options edns0
options trust-ad
EOF
        if [[ $script_is_root == "true" ]]; then
            cp "$script_path/resolv.conf" /etc/resolv.conf
        elif [[ $script_have_sudo == "true" ]]; then
            sudo cp "$script_path/resolv.conf" /etc/resolv.conf
        else
            true
        fi
    fi
}
export -f restore_dns
###############################################################################
# shellcheck disable=2317
# It seems shellcheck is not aware of trap
function cloudflare_cleanup() {
    warp-cli disconnect || true
        if [[ ! $(check_dns) ]]; then
            if [[ -f "$script_path/resolv.conf.backup" ]]; then
                if [[ $script_have_sudo == "true" ]]
                then
                    sudo rm -f /etc/resolv.conf
                    sudo cp "$script_path/resolv.conf.backup" /etc/resolv.conf
                    sudo rm -f "$script_path/resolv.conf.backup"
                elif [[ $script_is_root == "true" ]]
                then
                    rm -f /etc/resolv.conf
                    cp "$script_path/resolv.conf.backup" /etc/resolv.conf
                    sudo rm -f "$script_path/resolv.conf.backup"
                fi
            fi
        fi
        if [[ ! $(check_dns) ]]; then
            restore_dns
        fi
}
export -f cloudflare_cleanup
###############################################################################
trap cloudflare_cleanup INT
cloudflare_init "$@"
exit