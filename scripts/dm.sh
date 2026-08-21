#!/bin/bash

set -o pipefail

dmepath=""
modified_dme=""
modified_base=""
retval=1

for var; do
    if [[ $var != -* && $var == *.dme ]]; then
        dmepath=$(echo $var | sed -r 's/.{4}$//')
        break
    fi
done

if [[ $dmepath == "" ]]; then
    echo "No .dme file specified, aborting."
    exit 1
fi

modified_base="${dmepath}.modified"
modified_dme="${modified_base}.dme"

if [[ -e "$modified_dme" ]]; then
    rm -- "$modified_dme"
fi

cp -- "${dmepath}.dme" "$modified_dme"
if [[ $? != 0 ]]; then
    echo "Failed to make modified dme, aborting."
    exit 2
fi

for var; do
    arg=$(echo $var | sed -r 's/^.{2}//')
    if [[ $var == -D* ]]; then
        sed -i '1s!^!#define '$arg'\n!' "$modified_dme"
    elif [[ $var == -I* ]]; then
        sed -i 's!// BEGIN_INCLUDE!// BEGIN_INCLUDE\n#include "'$arg'"!' "$modified_dme"
    elif [[ $var == -M* ]]; then
        sed -i '1s/^/#define MAP_OVERRIDE\n/' "$modified_dme"
        sed -i 's!#include "maps\\_map_include.dm"!#include "maps\\'$arg'\\'$arg'.dm"!' "$modified_dme"
    fi
done

source "$( dirname "${BASH_SOURCE[0]}" )/sourcedm.sh"

if [[ $DM == "" ]]; then
    echo "Couldn't find the DreamMaker executable, aborting."
    exit 3
fi

"$DM" "$modified_dme" | tee build_log.txt
retval=$?

[[ -e "${modified_base}.dmb" ]] && mv -- "${modified_base}.dmb" "${dmepath}.dmb"
[[ -e "${modified_base}.rsc" ]] && mv -- "${modified_base}.rsc" "${dmepath}.rsc"

rm -- "$modified_dme"

exit $retval
