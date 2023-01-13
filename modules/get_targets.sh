#!/bin/bash
set -e
set -u
set -o pipefail

###############################################################################
export str_module_get_targets_version="0.0.1"
###############################################################################
export script_path="$HOME/kamenjar"
###############################################################################
export link_itarmy_json="https://raw.githubusercontent.com/db1000n-coordinators/LoadTestConfig/main/config.v0.7.json"
export link_jq_x32="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux32"
export link_jq_x64="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
export link_jq_x64_macos="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64"
###############################################################################
os_bits=$(getconf LONG_BIT)
if [ "$os_bits" != "64" ]; then
    os_bits="32"
fi
export os_bits
###############################################################################
function get_targets_init() {
    if ! command -v jq >/dev/null 2>&1; then
        # We have a local copy, use that
        if [[ -f "$script_path/bin/jq" ]]; then
            script_jq="$script_path/bin/jq"
            export script_jq
        fi
        # We don't have a local copy.
        if [[ "$script_jq" == "null" ]]; then
            if [[ $os_bits == "64" ]]; then
                download_link=$link_jq_x64
            fi
            if [[ $os_bits == "32" ]]; then
                download_link=$link_jq_x32
            fi
            while [[ ! -f "$script_path/bin/jq" ]]; do
                wait_for_internet
                curl -s -L --retry 10 --output "$script_path/bin/jq" --url "$download_link"
                chmod +x "$script_path/bin/jq"
            done
            script_jq="$script_path/bin/jq"
            export script_jq
        fi
    else
        # System jq found
        script_jq="jq"
        export script_jq
    fi
}
export -f get_targets_init
###############################################################################
# function is not called in module.
# shellcheck disable=2317
function get_targets(){
    wait_for_internet
    declare -a json_itarmy_paths=(
        ".jobs[].args.packet.payload.data.path"
        ".jobs[].args.connection.args.address"
    )
    declare -a link_targetlist_array=(
        "https://raw.githubusercontent.com/LordWarWar/transmit/main/targets/all.txt"
    )
    if [ -d "$script_path/targets" ]; then
        rm -rf "$script_path/targets" >/dev/null 2>&1
        mkdir -p "$script_path/targets/"
    fi
    cd "$script_path"

    local targets_got=0
    #####
    while [[ $targets_got == 0 ]]; do
        json=$(curl -s --retry 10 -L --url "$link_itarmy_json") >/dev/null 2>&1
        local num=1
        for path in "${json_itarmy_paths[@]}"; do
            touch "$script_path/targets/list$num.txt"
            lines=$(echo "$json" | $script_jq -r "$path" | sed '/null/d')
            if [[ $path == ".jobs[].args.connection.args.address" ]]; then
                touch "$script_path/targets/list$num.txt"
                for line in $lines; do
                    local output
                    output="tcp://$line"
                    echo "$output" >>"$script_path/targets/list$num.txt"
                done
            else
                echo "$lines" >>"$script_path/targets/list$num.txt"
            fi
            targets_got=$(wc -l <"$script_path/targets/list$num.txt")
            num=$((num + 1))
        done
    done
    rm -f "$script_path/targets/db1000n.json" >/dev/null 2>&1

    for file in "$script_path"/targets/*.txt; do
        sed -i '/^[[:space:]]*$/d' "$file"
        cat "$file" >>"$script_path/targets/itarmy.list"
    done

    for list in "${link_targetlist_array[@]}"; do
        curl -s -X GET --url "$list" --output "$script_path/targets/list$num.txt"
        targets_got=$(wc -l <"$script_path/targets/list$num.txt")
        num=$((num + 1))
    done

    for file in "$script_path"/targets/*.txt; do
        sed -i '/^[[:space:]]*$/d' "$file"
    done

    for file in "$script_path"/targets/*.txt; do
        cat "$file" >>"$script_path/targets/_targets.txt"
        rm -f "$file"
    done

    lines=$(cat "$script_path/targets/_targets.txt")
    rm -f "$script_path/targets/_targets.txt"
    for line in $lines; do
        if [[ $line == "http"* ]] || [[ $line == "tcp://"* ]]; then
            echo "$line" >>"$script_path/targets/all_targets.txt"
        fi
    done
    sort <"$script_path/targets/all_targets.txt" |
        uniq |
        sort -R >"$script_path/targets/uniq_targets.txt"
    rm -f "$script_path/targets/all_targets.txt"
}
export -f get_targets
get_targets_init "$@"
exit