#!/bin/bash
set -e
set -u
set -o pipefail
function cloudflare_init(){
    true
}
export -f cloudflare_init
cloudflare_init "$@"
exit