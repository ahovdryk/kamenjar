#!/bin/bash
set -e
set -u
set -o pipefail
function runner(){
    true
}
export -f runner
runner "$@"
exit