#!/bin/bash
set -e
set -u
set -o pipefail
###############################################################################
export str_module_mhddos_proxy_version="0.0.1"
###############################################################################
export script_path="$HOME/kamenjar"
export script_mhddos="null"
###############################################################################
export link_mhddos="https://github.com/LordWarWar/mhddos_proxy/archive/refs/heads/main.zip"
export link_unzip="https://oss.oracle.com/el4/unzip/unzip.tar"
###############################################################################
export str_mhddos_no_python=""
export str_mhddos_low_subversion=""
export str_mhddos_no_pip=""
export str_mhddos_no_venv=""
export str_mhddos_fail=""
###############################################################################
function mhddos_init(){
    printf '%s' "Module mhddos ver $str_module_mhddos_proxy_version"
    if ! command -v python3 >/dev/null 2>&1; then
        printf '%s' "$str_mhddos_no_python\n$str_mhddos_fail\n"
        # 2 is a Linux error code for "No such file or directory"
        # Keep your scripts clean! Use correct error codes!
        return 2
    fi
    python_commands='import sys; version=sys.version_info[:3]; print("{1}".format(*version))'
    python_subversion=$(python3 -c "$python_commands")
    if [[ $python_subversion -lt 8 ]]; then
        printf '%s' "$str_mhddos_low_subversion\n$str_mhddos_fail\n"
        # 38 is a Linux code for "Function not implemented"
        # Keep your scripts clean! Use correct error codes!
        return 38
    fi
    pip_output=$(
            python3 - <<EOF
try:
    import pip;
    print("Pip installed!")
except Exception:
    print("Pip failed!")
EOF
        )

    if [[ "$pip_output" == "Pip installed!" ]]; then
        true
    else
        link_getpip="https://bootstrap.pypa.io/get-pip.py"
        while [[ ! -f "$script_path/get_pip.py" ]]; do
            wait_for_internet
            curl -s -L --retry 10 --output "$script_path/get_pip.py" --url "$link_getpip"
        done
        python3 "$script_path/get_pip.py" --user >/dev/null 2>&1 || pip_fatal_fail="true"
        rm -f "$script_path/get_pip.py"
    fi

    if [[ $pip_fatal_fail == "true" ]]; then
        printf '%s' "$str_mhddos_no_pip\n$str_mhddos_fail\n"
        # 38 is a Linux code for "Function not implemented"
        # Keep your scripts clean! Use correct error codes!
        return 38
    fi
    venv_prepare
    local error_code=$?
    if [[ $error_code -eq 38 ]]
    then
        printf '%s' "$str_mhddos_no_venv\n$str_mhddos_fail\n"
        # 38 is a Linux code for "Function not implemented"
        # Keep your scripts clean! Use correct error codes!
        return 38
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
    while [[ ! -d "$script_path/mhddos_proxy" ]]; do
        while [[ ! -f "$script_path/mhddos_proxy.zip" ]]; do
            wait_for_internet
            curl -s -L --url "$link_mhddos" --output "$script_path/mhddos_proxy.zip"
        done
        $script_unzip "$script_path/mhddos_proxy.zip" -d "$script_path" >/dev/null 2>&1
        mv "$script_path/mhddos_proxy-main" "$script_path/mhddos_proxy"
        rm -f "$script_path/mhddos_proxy.zip"
    done
    # shellcheck disable=1091
    source "$script_path/venv/bin/activate"
    python3 -m pip install --upgrade pip # >/dev/null 2>&1
    python3 -m pip install -r "$script_path/mhddos_proxy/requirements.txt" # >/dev/null 2>&1
    deactivate

}
export -f mhddos_init
###############################################################################
function venv_prepare() {
    venv_output=$(
        python3 - <<EOF
try:
    import venv;
    print("venv installed!")
except Exception:
    print("venv failed!")
EOF
    )
    if [[ $venv_output == "venv installed!" ]]; then
        export py_venv="python3 -m venv"
        $py_venv "$script_path/venv" >/dev/null 2>&1 || venv_output="venv failed!"
    fi
    if [[ "$venv_output" == "venv failed!" ]]; then
        have_venv=$(
            python3 - <<EOF
try:
    import virtualenv;
    print("virtualenv found!")
except Exception:
    print("virtualenv failed!")
EOF
        )
        if [[ $have_venv == "virtualenv failed!" ]]; then
            python3 -m pip install virtualenv >/dev/null 2>&1
        fi
        export py_venv="python3 -m virtualenv"
        $py_venv "$script_path/venv" >/dev/null 2>&1 || export venv_output="fail"
    fi
    if [[ $venv_output == "fail" ]]; then
        # 38 is a Linux code for "Function not implemented"
        # Keep your scripts clean! Use correct error codes!
        return 38
    fi
}
export -f venv_prepare
###############################################################################
# shellcheck disable=2317
# It seems shellcheck is not aware of trap
function mhddos_cleanup() {
    pkill -f "$script_path/mhddos_proxy/runner.py" || true
    rm -rf "$script_path/mhddos_proxy" || true
}
###############################################################################
###############################################################################
###############################################################################
mhddos_init "$@"
exit