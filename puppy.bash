#!/bin/bash

set -e

case "$OSTYPE" in
    darwin* )
        HOMEPORT_OS=OSX
        ;;
    linux* )
        HOMEPORT_OS=Linux
        ;;
    * )
        abend "Puppy will only run on OS X or Linux."
        ;;
esac

if [ "$1" == "module" ]; then
    echo $0
  echo 'Please do not execute these programs directly. Use `puppy`.'
  exit 1
fi

# At the top of every module. This will gather a usage message to share with the
# user if we abend.
function puppy() {
    [ "$1" == "module" ] || fail "invalid argument to puppy"
    local message; local spaces;
    IFS="\000" read -r -d'\000' message && true
    spaces=$(
        echo "$message" | sed -e '/^$/d' -e 's/^\( *\).*/\1/' | \
            sed -e '1h;H;g;s/[^\n]/#/g;s/\(#*\)\n\1/\n/;G;/^\n/s/\n.*\n\(.*\)\n.*/\1/;s/.*\n//;h;$!d'
    )
    USAGE="$(echo "$message" | sed -e "s/^$spaces//")"
}

function puppy_readlink() {
    file=$1
    if [ "$HOMEPORT_OS" = "OSX" ]; then
        if [ -L "$file" ]; then
            readlink $1
        else
            echo "$file"
        fi
    else
        readlink -f $1
    fi
}

function puppy_absolutize() {
    expanded=$(cd ${1/*} && puppy_readlink $1)
    readlink $1 1>&2
    echo x $expanded 1>&2
    base=${expanded##*/}
    dir=$(cd ${expanded%/*} && pwd -P)
    echo "$dir/$base"
}

function usage() {
  local code=$1
  echo "$USAGE"
  exit $code
}

function abend() {
  local message=$1
  echo "error: $message"
  usage 1
}

function puppy_configuration() {
    puppy_tag=$1
    puppy_shell=$(docker images | awk -v user=$USER -v tag=$puppy_tag '
        $1 == "puppy_shell-"tag && $2 == user {print $1":"$2}
    ')

    if [  -z "$puppy_shell" ]; then
        printf '%s %q\n' abend 'no shell. please create shell with `puppy create`'
    else
        echo "puppy_shell=$puppy_shell"
        docker run --rm $puppy_shell cat /etc/puppy/configuration
    fi
}

function puppy_perpetuate () {
    local command="${0%.*}/$1.bash"
    shift
    $command "$@"
}

function puppy_exec() {
    local command=$1

    [ -z "$command" ] && abend "TODO: write usage"

    local action="$HOMEPORT_PATH/lib/$command.bash"

    [ ! -e "$action"  ] && abend "invalid action: puppy $command"

    shift

    export puppy_namespace="$puppy_docker_hub_account"
    export HOMEPORT_PATH puppy_docker_hub_account puppy_unix_user puppy_tag \
        puppy_image_name puppy_unix_user puppy_home_volume
    export -f usage abend getopt puppy puppy_configuration puppy_perpetuate

    "$action" "$@"
}

puppy_file=$0

while [ -L "$puppy_file" ]; do
    expanded=$(puppy_readlink "$puppy_file")
    pushd "${puppy_file%/*}" > /dev/null
    pushd "${expanded%/*}" > /dev/null
    puppy_path=$(pwd)
    popd > /dev/null
    popd > /dev/null
    puppy_file="$puppy_path/${puppy_file##*/}"
done

pushd "${puppy_file%/*}" > /dev/null
HOMEPORT_PATH=$(pwd)
popd > /dev/null

source "$HOMEPORT_PATH/getopt.bash"

# Node that the `+` in the options sets scanning mode to stop at the first
# non-option parameter, otherwise we'd have to explicilty use `--` before the
# sub-command.
declare argv
argv=$(getopt --options +t:u:h: --long tag:,user:,hub: -- "$@") || return
eval "set -- $argv"

puppy_tag=default
puppy_unix_user=$USER

while true; do
    case "$1" in
        --user | -u)
            shift
            puppy_unix_user=$1
            shift
            ;;
        --hub | -h)
            shift
            puppy_docker_hub_account=$1
            shift
            ;;
        --tag | -t)
            shift
            puppy_tag=$1
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

if [ ! -z "$puppy_docker_hub_account" ]; then
    puppy_image_name="${puppy_docker_hub_account}/"
fi
puppy_image_name+=puppy_${USER}_${puppy_unix_user}_${puppy_tag}

puppy_home_volume="puppy_home_${USER}_${puppy_unix_user}"

puppy_exec "$@"
