#!/bin/bash
set -e
set -u
set -o pipefail
function kickstart(){
    true
}
export -f kickstart
kickstart "$@"
exit