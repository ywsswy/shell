#!/usr/bin/env bash

#<ESC>这种ctrl命令

if [ `basename $0` != 'bashdb' ];then
    arg0=$0
else
    arg0=$1
    shift
fi
thisdir=$(dirname $(readlink -f $arg0))

function HashGet()
{
    md5hash=$(echo -n "$1" |md5sum)
    echo $((16#${md5hash:0:15}))
}

gEnableLogLevelVec=(
"-DEBUG"
"-INFO0"
"ERROR"
)

gEnableLogLevelMapk=()

for ((i = 0; i < ${#gEnableLogLevelVec[*]}; ++i))do
    hash_index=$(HashGet "${gEnableLogLevelVec[$i]}")
    gEnableLogLevelMapk[${hash_index}]="${gEnableLogLevelVec[$i]}"
done

function YLog()
{
    if [ "${gDisableLogLevelCheck+set}" != "" ];then
        echo "$(date +"%Y-%m-%d %H:%M:%S") [$2]: [$arg0:$1]:${*:3}" >&2
    else
        hash_index=$(HashGet "$2")
        if [ "${gEnableLogLevelMapk[${hash_index}]+set}" != "" ];then
            echo "$(date +"%Y-%m-%d %H:%M:%S") [$2]: [$arg0:$1]:${*:3}" >&2
        fi
    fi
}

function KillScript()
{
    $(YLog "$1" ERROR "${*:2}")
    kill 0
    sleep 1
    kill -9 0
}

$(YLog $LINENO DEBUG "para_num: $#")

function GetStuffCmd()
{
    stuff_cmd=""
    i=0
    while IFS= ;read -r line;do
        $(YLog $LINENO DEBUG "line: $line")
        if [ $i -ne 0 ];then
            stuff_cmd="${stuff_cmd}\n${line}"
        else
            stuff_cmd="${stuff_cmd}${line}"
        fi
        i=$((i + 1))
    done
    echo "$stuff_cmd"
}

if [ "$1" == "-p"\
    -a $# -ge 2 ];then
    $(YLog $LINENO DEBUG "${*:2}")
    $(YLog $LINENO DEBUG "${#2}")
    stuff_cmd=$(GetStuffCmd)
    $(YLog $LINENO INFO0 "stuff cmd:${stuff_cmd}")
    arr_s="${2//,/ }"
    $(YLog $LINENO DEBUG "${arr_s}")
    arr=($arr_s)
    for ((i = 0; i < ${#arr[*]}; ++i))do
        $(YLog $LINENO DEBUG "${arr[$i]}")
        $(YLog $LINENO DEBUG "${#arr[$i]}")
        res=$(screen -p "${arr[$i]}" -X stuff "$stuff_cmd")
    done
else
    $(KillScript $LINENO "usage: -p <screen1>,<screen2>")
fi
