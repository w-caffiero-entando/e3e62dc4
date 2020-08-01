#!/bin/bash

H() { echo -e "Helps managing the system that hosts the quickstart VM | Syntax: ${0##*/} update-hosts-file ..."; }
[ "$1" = "-h" ] && H && exit 0

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/.." || { echo "Internal error: unable to find the script source dir"; exit; }

. s/_base.sh

test_check_ver_num
