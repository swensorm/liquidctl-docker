#!/bin/bash
#
# Templated from jonasmalacofilho's liquidcfg dotfile:
# https://github.com/jonasmalacofilho/dotfiles/blob/main/liquidctl/liquidcfg

# we actually want to propagate spaces in $LL, $KRAKEN, etc.
# shellcheck disable=SC2086

set -e

LL="liquidctl $EXTRAOPTIONS"
KRAKEN="--match kraken"

function panic() {
    set +ex
    code=$?
    $LL $KRAKEN set fan speed 100
    $LL $KRAKEN set pump speed 100
    exit $code
}

function show_help() {
    echo "Usage:"
    echo " $0 [options]"
    echo
    echo "Apply static settings to my liquidctl devices."
    echo
    echo "Options:"
    echo "--flush              Run the pump at 100% for a few seconds"
    echo "--verbose                List all devices and commands."
    echo "--help                   Show this help"
}

flush=0
verbose=0


OPTS=$(getopt -o ab:Cd:f:h:l:i:p:svw:x --long flush,verbose,help -n "$0" -- "$@")
eval set -- "$OPTS"

while true; do
    case "$1" in
        --flush ) flush=1; shift;;
        --verbose ) verbose=1; shift;;
        --help ) show_help; exit;;
        -- ) shift; break;;
        * ) echo "Unrecognized option: $1" ; show_help; exit 1 ;;
    esac
done


if [ "$verbose" -ne 0 ]; then
    set -x
    echo "liquidctl version"
    liquidctl --version
    echo "Available devices"
    liquidctl list --verbose
fi


echo "Initializing all devices"
$LL initialize all || panic
$LL list

if [ "$flush" -ne 0 ]; then
    echo "Flushing the pump for 10 seconds"
    $LL set pump speed 100
    sleep 10
fi


echo "Applying a balanced cooling profile"
liquidctl set pump speed 0 35  30 35  33 70  36 100 || panic
liquidctl set fan speed 0 35  30 35  33 50  36 75  40 100 || panic

lastStatus=""
while true; do
    liquidStatus=$(liquidctl status)
    if [ "$liquidStatus" != "$lastStatus" ]; then
        echo "$liquidStatus"
        lastStatus=$liquidStatus
    fi

    sleep 15
done
