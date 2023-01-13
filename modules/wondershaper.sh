#!/bin/bash
set -e
set -u
set -o pipefail
function wondershaper_init(){
    true
}
export -f wondershaper_init
wondershaper_init "$@"
exit