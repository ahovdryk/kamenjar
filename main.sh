#!/bin/bash
set -e
set -u
set -o pipefail
function main(){
    true
}
export -f main
main "$@"
exit